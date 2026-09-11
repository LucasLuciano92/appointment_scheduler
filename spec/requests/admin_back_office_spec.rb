require "rails_helper"

RSpec.describe "Admin back office", type: :request do
  include BookingSetup

  before do
    setup_booking
    @admin = User.create!(first_name: "Admin", last_name: "Salón", email_address: "admin@example.com",
      password: "password123", role: :admin)
  end

  it "prevents guests from reading or mutating administrative resources" do
    resources = [ [ :services, @service ], [ :staff_members, @staff ], [ :service_offerings, @offering ],
      [ :availabilities, @availability ], [ :customers, @customer ] ]
    get admin_root_path
    expect(response).to redirect_to(new_admin_session_path)

    resources.each do |name, record|
      path = "/admin/#{name}"
      get path
      expect(response).to redirect_to(new_admin_session_path)
      post path, params: {}
      expect(response).to redirect_to(new_admin_session_path)
      patch "#{path}/#{record.id}", params: {}
      expect(response).to redirect_to(new_admin_session_path)
      delete "#{path}/#{record.id}"
      expect(response).to redirect_to(new_admin_session_path)
      expect(record.class.exists?(record.id)).to be(true)
    end

    appointment = build_appointment
    appointment.save!
    [ admin_appointments_path, new_admin_appointment_path, admin_appointment_path(appointment),
      edit_admin_appointment_path(appointment) ].each do |path|
      get path
      expect(response).to redirect_to(new_admin_session_path)
    end
    post admin_appointments_path
    expect(response).to redirect_to(new_admin_session_path)
    [ admin_appointment_path(appointment), cancel_admin_appointment_path(appointment),
      complete_admin_appointment_path(appointment) ].each do |path|
      patch path
      expect(response).to redirect_to(new_admin_session_path)
    end
    expect(appointment.reload).to be_scheduled
  end

  it "rejects wrong credentials customers and inactive administrators" do
    [ [ @admin.email_address, "wrong" ], [ @customer.email_address, "password123" ] ].each do |email, password|
      expect do
        post admin_session_path, params: { session: { email_address: email, password: password } }
      end.not_to change(AdminSession, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(rendered_page).to have_css(".flash.alert", text: /Email o contraseña/)
    end
    @admin.update!(active: false)
    sign_in
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "enforces session access through login logout expiry and revocation" do
    sign_in
    expect(response).to redirect_to(admin_root_path)
    expect(@admin.admin_sessions.count).to eq(1)
    get admin_root_path
    expect(response).to have_http_status(:success)
    expect(response.headers["Cache-Control"]).to eq("no-store")
    delete admin_session_path
    expect(response).to redirect_to(new_admin_session_path)
    expect(@admin.admin_sessions.count).to eq(0)
    get admin_root_path
    expect(response).to redirect_to(new_admin_session_path)

    sign_in
    @admin.admin_sessions.last.update!(expires_at: 1.minute.ago)
    get admin_root_path
    expect(response).to redirect_to(new_admin_session_path)
    sign_in
    @admin.update!(active: false)
    get admin_root_path
    expect(response).to redirect_to(new_admin_session_path)
  end

  it "invalidates administrative access after changing role or password" do
    sign_in
    @admin.update!(role: :customer)
    get admin_root_path
    expect(response).to redirect_to(new_admin_session_path)
    @admin.update!(role: :admin)
    sign_in
    @admin.update!(password: "newpassword123")
    expect(@admin.admin_sessions).to be_empty
    get admin_root_path
    expect(response).to redirect_to(new_admin_session_path)
  end

  it "renders all catalog and appointment pages with their forms" do
    sign_in
    appointment = build_appointment
    appointment.save!
    [ [ "services", @service ], [ "staff_members", @staff ], [ "service_offerings", @offering ],
      [ "availabilities", @availability ], [ "customers", @customer ], [ "appointments", appointment ] ].each do |name, record|
      [ "/admin/#{name}", "/admin/#{name}/new", "/admin/#{name}/#{record.id}",
        "/admin/#{name}/#{record.id}/edit" ].each do |path|
        get path
        expect(response).to have_http_status(:success), path
        expect(rendered_page).to have_css("html[lang=es]")
        expect(rendered_page).to have_css("nav.navigation")
        expect(response.body).not_to match(/translation missing/i)
      end
    end
    get admin_root_path
    expect(response).to have_http_status(:success)
    expect(rendered_page).to have_css(".stat", count: 4)
  end

  it "handles invalid input activation and deletion for services" do
    sign_in
    expect do
      post admin_services_path, params: { service: { name: "", price: -1, duration_minutes: 0 } }
    end.not_to change(Service, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(rendered_page).to have_css(".errors", text: /es obligatorio/)

    post admin_services_path, params: { service: { name: "Color", duration_minutes: 60, price: 200 } }
    service = Service.find_by!(name: "Color")
    expect(response).to redirect_to(admin_service_path(service))
    patch admin_service_path(service), params: { service: { name: "Color completo", active: false } }
    expect(response).to redirect_to(admin_service_path(service))
    expect(service.reload).not_to be_active
    delete admin_service_path(service)
    expect(response).to redirect_to(admin_services_path)
    expect(Service.exists?(service.id)).to be(false)
  end

  it "creates updates and removes staff offers and availability" do
    sign_in
    post admin_staff_members_path, params: { staff_member: { first_name: "Maria", last_name: "Lopez" } }
    staff = StaffMember.find_by!(first_name: "Maria")
    expect(response).to redirect_to(admin_staff_member_path(staff))
    post admin_service_offerings_path,
      params: { service_offering: { staff_member_id: staff.id, service_id: @service.id } }
    offering = staff.service_offerings.sole
    expect(response).to redirect_to(admin_service_offering_path(offering))
    post admin_availabilities_path,
      params: { availability: { staff_member_id: staff.id, day_of_week: "monday", start_time: "09:00", end_time: "13:00" } }
    availability = staff.availabilities.sole
    expect(response).to redirect_to(admin_availability_path(availability))
    patch admin_availability_path(availability), params: { availability: { end_time: "08:00" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(rendered_page).to have_css(".errors", text: /posterior al inicio/)
    patch admin_availability_path(availability), params: { availability: { active: false } }
    expect(availability.reload).not_to be_active
    patch admin_service_offering_path(offering), params: { service_offering: { active: false } }
    expect(offering.reload).not_to be_active
    patch admin_staff_member_path(staff), params: { staff_member: { active: false } }
    expect(staff.reload).not_to be_active
    delete admin_availability_path(availability)
    expect(response).to redirect_to(admin_availabilities_path)
    delete admin_service_offering_path(offering)
    expect(response).to redirect_to(admin_service_offerings_path)
    delete admin_staff_member_path(staff)
    expect(response).to redirect_to(admin_staff_members_path)
  end

  it "prevents customer promotion and administrator editing through customer routes" do
    sign_in
    post admin_customers_path, params: { customer: { first_name: "Eva", last_name: "Perez",
      email_address: "eva@example.com", password: "password123", password_confirmation: "password123", role: "admin" } }
    customer = User.find_by!(email_address: "eva@example.com")
    expect(response).to redirect_to(admin_customer_path(customer))
    expect(customer).to be_customer
    digest = customer.password_digest
    patch admin_customer_path(customer), params: { customer: { phone: "123", password: "",
      password_confirmation: "", role: "admin", active: false } }
    expect(response).to redirect_to(admin_customer_path(customer))
    expect(customer.reload.password_digest).to eq(digest)
    expect(customer).to be_customer
    expect(customer).not_to be_active
    [ admin_customer_path(@admin), edit_admin_customer_path(@admin) ].each do |path|
      get path
      expect(response).to have_http_status(:not_found)
    end
    patch admin_customer_path(@admin), params: { customer: { active: false } }
    expect(response).to have_http_status(:not_found)
    expect(@admin.reload).to be_active
    delete admin_customer_path(customer)
    expect(response).to redirect_to(admin_customers_path)
  end

  it "shows errors when booked records cannot be deleted" do
    sign_in
    appointment = build_appointment
    appointment.save!
    [ admin_customer_path(@customer), admin_service_offering_path(@offering), admin_service_path(@service),
      admin_staff_member_path(@staff) ].each do |path|
      delete path
      expect(response).to have_http_status(:unprocessable_content)
      expect(rendered_page).to have_css(".errors")
      expect(response.body).not_to match(/translation missing/i)
    end
    delete admin_appointment_path(appointment)
    expect(response).to have_http_status(:not_found)
    expect(Appointment.exists?(appointment.id)).to be(true)
  end

  it "follows business rules when reserving rescheduling cancelling and completing" do
    sign_in
    attrs = { customer_id: @customer.id, service_offering_id: @offering.id,
      starts_at: @starts_at.strftime("%Y-%m-%dT%H:%M"), status: "completed" }
    post admin_appointments_path, params: { appointment: attrs }
    appointment = Appointment.sole
    expect(response).to redirect_to(admin_appointment_path(appointment))
    expect(appointment).to be_scheduled
    expect(appointment.starts_at).to eq(@starts_at)
    post admin_appointments_path, params: { appointment: attrs }
    expect(response).to have_http_status(:unprocessable_content)
    expect(rendered_page).to have_css(".errors", text: /superpone/)
    patch complete_admin_appointment_path(appointment)
    expect(response).to have_http_status(:unprocessable_content)
    patch admin_appointment_path(appointment), params: { appointment: {
      starts_at: (@starts_at + 1.hour).strftime("%Y-%m-%dT%H:%M"), ends_at: @starts_at, status: "completed" } }
    expect(response).to redirect_to(admin_appointment_path(appointment))
    expect(appointment.reload.ends_at).to eq(@starts_at + 90.minutes)
    expect(appointment).to be_scheduled
    travel_to appointment.ends_at
    sign_in
    patch complete_admin_appointment_path(appointment)
    expect(response).to redirect_to(admin_appointment_path(appointment))
    expect(appointment.reload).to be_completed
    patch cancel_admin_appointment_path(appointment)
    expect(response).to have_http_status(:unprocessable_content)
    patch admin_appointment_path(appointment), params: { appointment: { notes: "Atendido" } }
    expect(response).to redirect_to(admin_appointment_path(appointment))
    expect(appointment.reload.notes).to eq("Atendido")
  end

  it "releases cancelled slots and prevents terminal turns from being rescheduled" do
    sign_in
    appointment = build_appointment
    appointment.save!
    patch cancel_admin_appointment_path(appointment)
    expect(response).to redirect_to(admin_appointment_path(appointment))
    patch admin_appointment_path(appointment), params: { appointment: { starts_at: @starts_at + 1.hour } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(appointment.reload).to be_cancelled
    expect(build_appointment.save).to be(true)
  end

  it "filters the agenda and handles malformed dates" do
    sign_in
    appointment = build_appointment
    appointment.save!
    get admin_appointments_path,
      params: { date: @starts_at.to_date.iso8601, status: "scheduled", staff_member_id: @staff.id }
    expect(rendered_page).to have_css("a[href='#{admin_appointment_path(appointment)}']")
    get admin_appointments_path, params: { status: "cancelled" }
    expect(rendered_page).not_to have_css("a[href='#{admin_appointment_path(appointment)}']")
    get admin_appointments_path, params: { date: "invalid" }
    expect(response).to redirect_to(admin_appointments_path)
    get admin_appointments_path, params: { status: "invalid" }
    expect(response).to redirect_to(admin_appointments_path)
  end

  it "falls back to the first page for unexpected pagination values" do
    sign_in
    [ [ "2" ], { number: "2" }, "invalid", "-1", "0", "2.5", "9" * 100 ].each do |page|
      get admin_services_path, params: { page: page }
      expect(response).to have_http_status(:success)
      expect(rendered_page).to have_css(".pagination", text: /Página 1/)
    end
  end

  it "shows a validation notice for unexpected filters" do
    sign_in
    %i[date status staff_member_id].each do |key|
      [ [ "value" ], { value: "value" } ].each do |value|
        get admin_appointments_path, params: { key => value }
        expect(response).to redirect_to(admin_appointments_path)
        follow_redirect!
        expect(response).to have_http_status(:success)
        expect(rendered_page).to have_css(".flash.alert", text: /Revisá/)
      end
    end
    [ { date: "2030-02-30" }, { date: "20300108" }, { staff_member_id: "invalid" },
      { staff_member_id: "-1" }, { staff_member_id: "9" * 100 } ].each do |filters|
      get admin_appointments_path, params: filters
      expect(response).to redirect_to(admin_appointments_path)
    end
  end

  it "paginates lists and escapes user supplied HTML" do
    sign_in
    26.times { |index| Service.create!(name: "Service #{index}", duration_minutes: 30, price: 10) }
    get admin_services_path
    expect(rendered_page).to have_css("tbody tr", count: 25)
    expect(rendered_page).to have_link("Siguiente →")
    get admin_services_path, params: { page: 2 }
    expect(rendered_page).to have_css("tbody tr", count: 2)
    @service.update!(name: "<script>alert('xss')</script>")
    get admin_service_path(@service)
    expect(response.body).not_to include("<script>alert('xss')</script>")
    expect(response.body).to include("&lt;script&gt;")
  end

  it "requires a CSRF token for login when forgery protection is enabled" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    expect { sign_in }.not_to change(AdminSession, :count)
    expect(response).to have_http_status(:unprocessable_content)
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  def rendered_page
    Capybara.string(response.body)
  end

  def sign_in
    post admin_session_path,
      params: { session: { email_address: @admin.email_address, password: "password123" } }
  end
end
