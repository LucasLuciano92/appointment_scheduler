require "rails_helper"

RSpec.describe "API V1", type: :request do
  include BookingSetup

  before { setup_booking }
  after { travel_back }

  def json
    JSON.parse(response.body)
  end

  def authorization_for(user = @customer)
    _api_session, token = ApiSession.issue!(user)
    { "Authorization" => "Bearer #{token}" }
  end

  describe "authentication and profile" do
    it "registers only a customer and returns a non-persisted bearer token" do
      post "/api/v1/registration", params: {
        user: {
          first_name: "Eva", last_name: "Diaz", email_address: "EVA@example.com",
          password: "password123", password_confirmation: "password123", role: "admin", active: false
        }
      }, as: :json

      expect(response).to have_http_status(:created)
      customer = User.find_by!(email_address: "eva@example.com")
      expect(customer).to be_customer
      expect(customer).to be_active
      expect(customer.api_sessions.first.token_digest).not_to eq(json.fetch("token"))
      expect(response.headers.fetch("Cache-Control")).to include("no-store")
    end

    it "returns structured validation errors during registration" do
      post "/api/v1/registration", params: {
        user: { first_name: "", last_name: "", email_address: "bad", password: "short" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json.dig("error", "code")).to eq("validation_failed")
      expect(json.dig("error", "details")).to include("first_name", "email_address", "password")
    end

    it "logs in active customers but never admins" do
      post "/api/v1/session", params: {
        session: { email_address: @customer.email_address, password: "password123" }
      }, as: :json
      expect(response).to have_http_status(:created)
      expect(json.fetch("token")).to be_present

      admin = User.create!(first_name: "Ada", last_name: "Admin", email_address: "admin@example.com",
        password: "password123", role: :admin)
      post "/api/v1/session", params: {
        session: { email_address: admin.email_address, password: "password123" }
      }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "protects the profile, updates only allowed fields and revokes a logged-out token" do
      headers = authorization_for
      get "/api/v1/profile", headers: headers
      expect(response).to have_http_status(:ok)
      expect(json.dig("data", "id")).to eq(@customer.id)

      patch "/api/v1/profile", params: { user: { first_name: "Anita", role: "admin", active: false } },
        headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(@customer.reload).to have_attributes(first_name: "Anita", role: "customer", active: true)

      delete "/api/v1/session", headers: headers
      expect(response).to have_http_status(:no_content)
      get "/api/v1/profile", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects expired and malformed bearer tokens" do
      _api_session, token = ApiSession.issue!(@customer)
      ApiSession.last.update!(expires_at: 1.minute.ago)

      get "/api/v1/profile", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:unauthorized)
      get "/api/v1/profile", headers: { "Authorization" => "Basic #{token}" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "public catalog and availability" do
    it "lists and shows only active services" do
      inactive = Service.create!(name: "Hidden", duration_minutes: 45, price: 10, active: false)

      get "/api/v1/services"
      expect(response).to have_http_status(:ok)
      expect(json.fetch("data").pluck("id")).to eq([ @service.id ])

      get "/api/v1/services/#{inactive.id}"
      expect(response).to have_http_status(:not_found)
    end

    it "lists only active staff offerings for an active service" do
      inactive_staff = StaffMember.create!(first_name: "No", last_name: "Visible", active: false)
      ServiceOffering.create!(service: @service, staff_member: inactive_staff)

      get "/api/v1/services/#{@service.id}/staff_members"

      expect(response).to have_http_status(:ok)
      expect(json.fetch("data")).to contain_exactly(include(
        "id" => @staff.id, "service_offering_id" => @offering.id
      ))
    end

    it "returns available slots and excludes occupied intervals" do
      @availability.update!(start_time: "09:00", end_time: "11:00")
      AppointmentBooking.save(build_appointment, {})

      get "/api/v1/service_offerings/#{@offering.id}/available_slots",
        params: { date: @starts_at.to_date.iso8601 }

      expect(response).to have_http_status(:ok)
      expect(json.fetch("data").pluck("starts_at")).not_to include(@starts_at.iso8601)
      expect(json.fetch("data").size).to eq(3)
    end

    it "validates the requested availability date" do
      get "/api/v1/service_offerings/#{@offering.id}/available_slots", params: { date: "not-a-date" }

      expect(response).to have_http_status(:bad_request)
      expect(json.dig("error", "code")).to eq("invalid_date")
    end
  end

  describe "customer appointments" do
    it "creates a reservation for the authenticated customer" do
      other = User.create!(first_name: "Otro", last_name: "Cliente", email_address: "other@example.com",
        password: "password123")

      post "/api/v1/appointments", params: {
        appointment: {
          customer_id: other.id, service_offering_id: @offering.id,
          starts_at: @starts_at.iso8601, notes: "Sin perfume"
        }
      }, headers: authorization_for, as: :json

      expect(response).to have_http_status(:created)
      appointment = Appointment.find(json.dig("data", "id"))
      expect(appointment).to have_attributes(customer: @customer, status: "scheduled", notes: "Sin perfume")
    end

    it "returns booking validation failures without creating a record" do
      post "/api/v1/appointments", params: {
        appointment: { service_offering_id: @offering.id, starts_at: 1.hour.ago.iso8601 }
      }, headers: authorization_for, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json.dig("error", "code")).to eq("validation_failed")
    end

    it "lists and shows only the authenticated customer's appointments" do
      own = Appointment.create!(customer: @customer, service_offering: @offering, starts_at: @starts_at)
      other = User.create!(first_name: "Otro", last_name: "Cliente", email_address: "other@example.com",
        password: "password123")
      other_appointment = Appointment.create!(customer: other, service_offering: @offering,
        starts_at: @starts_at + 1.hour)
      headers = authorization_for

      get "/api/v1/appointments", headers: headers
      expect(json.fetch("data").pluck("id")).to eq([ own.id ])

      get "/api/v1/appointments/#{other_appointment.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "cancels only a future scheduled appointment owned by the customer" do
      appointment = Appointment.create!(customer: @customer, service_offering: @offering,
        starts_at: @starts_at)

      patch "/api/v1/appointments/#{appointment.id}/cancel", headers: authorization_for
      expect(response).to have_http_status(:ok)
      expect(appointment.reload).to be_cancelled

      patch "/api/v1/appointments/#{appointment.id}/cancel", headers: authorization_for
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json.dig("error", "code")).to eq("not_cancellable")
    end

    it "validates an optional status filter" do
      get "/api/v1/appointments", params: { status: "unknown" }, headers: authorization_for

      expect(response).to have_http_status(:bad_request)
      expect(json.dig("error", "code")).to eq("invalid_status")
    end
  end
end
