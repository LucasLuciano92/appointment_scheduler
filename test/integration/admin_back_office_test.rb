require "test_helper"
require_relative "../support/booking_setup"

class AdminBackOfficeTest < ActionDispatch::IntegrationTest
  include BookingSetup

  setup do
    setup_booking
    @admin = User.create!(first_name: "Admin", last_name: "Salón", email_address: "admin@example.com",
      password: "password123", role: :admin)
  end

  test "guests cannot read or mutate administrative resources" do
    resources = [ [ :services, @service ], [ :staff_members, @staff ], [ :service_offerings, @offering ],
      [ :availabilities, @availability ], [ :customers, @customer ] ]
    get admin_root_path
    assert_redirected_to new_admin_session_path
    resources.each do |name, record|
      path = "/admin/#{name}"
      get path
      assert_redirected_to new_admin_session_path
      post path, params: {}
      assert_redirected_to new_admin_session_path
      patch "#{path}/#{record.id}", params: {}
      assert_redirected_to new_admin_session_path
      delete "#{path}/#{record.id}"
      assert_redirected_to new_admin_session_path
      assert record.class.exists?(record.id)
    end
    appointment = build_appointment
    appointment.save!
    [ admin_appointments_path, new_admin_appointment_path, admin_appointment_path(appointment), edit_admin_appointment_path(appointment) ].each do |path|
      get path
      assert_redirected_to new_admin_session_path
    end
    post admin_appointments_path
    assert_redirected_to new_admin_session_path
    [ admin_appointment_path(appointment), cancel_admin_appointment_path(appointment), complete_admin_appointment_path(appointment) ].each do |path|
      patch path
      assert_redirected_to new_admin_session_path
    end
    assert appointment.reload.scheduled?
  end

  test "login rejects wrong credentials customers and inactive administrators" do
    [ [ @admin.email_address, "wrong" ], [ @customer.email_address, "password123" ] ].each do |email, password|
      assert_no_difference "AdminSession.count" do
        post admin_session_path, params: { session: { email_address: email, password: password } }
      end
      assert_response :unprocessable_entity
      assert_select ".flash.alert", /Email o contraseña/
    end
    @admin.update!(active: false)
    sign_in
    assert_response :unprocessable_entity
  end

  test "login logout expiry and revocation enforce session access" do
    sign_in
    assert_redirected_to admin_root_path
    assert_equal 1, @admin.admin_sessions.count
    get admin_root_path
    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    delete admin_session_path
    assert_redirected_to new_admin_session_path
    assert_equal 0, @admin.admin_sessions.count
    get admin_root_path
    assert_redirected_to new_admin_session_path

    sign_in
    @admin.admin_sessions.last.update!(expires_at: 1.minute.ago)
    get admin_root_path
    assert_redirected_to new_admin_session_path
    sign_in
    @admin.update!(active: false)
    get admin_root_path
    assert_redirected_to new_admin_session_path
  end

  test "changing role or password invalidates administrative access" do
    sign_in
    @admin.update!(role: :customer)
    get admin_root_path
    assert_redirected_to new_admin_session_path
    @admin.update!(role: :admin)
    sign_in
    @admin.update!(password: "newpassword123")
    assert_empty @admin.admin_sessions
    get admin_root_path
    assert_redirected_to new_admin_session_path
  end

  test "all catalog pages and appointment pages render their forms" do
    sign_in
    appointment = build_appointment
    appointment.save!
    [ [ "services", @service ], [ "staff_members", @staff ], [ "service_offerings", @offering ],
      [ "availabilities", @availability ], [ "customers", @customer ], [ "appointments", appointment ] ].each do |name, record|
      [ "/admin/#{name}", "/admin/#{name}/new", "/admin/#{name}/#{record.id}", "/admin/#{name}/#{record.id}/edit" ].each do |path|
        get path
        assert_response :success, path
        assert_select "html[lang=es]"
        assert_select "nav.navigation"
        assert_no_match(/translation missing/i, response.body)
      end
    end
    get admin_root_path
    assert_response :success
    assert_select ".stat", count: 4
  end

  test "service CRUD handles invalid input activation and deletion" do
    sign_in
    assert_no_difference "Service.count" do
      post admin_services_path, params: { service: { name: "", price: -1, duration_minutes: 0 } }
    end
    assert_response :unprocessable_entity
    assert_select ".errors", /es obligatorio/
    post admin_services_path, params: { service: { name: "Color", duration_minutes: 60, price: 200 } }
    service = Service.find_by!(name: "Color")
    assert_redirected_to admin_service_path(service)
    patch admin_service_path(service), params: { service: { name: "Color completo", active: false } }
    assert_redirected_to admin_service_path(service)
    assert_not service.reload.active?
    delete admin_service_path(service)
    assert_redirected_to admin_services_path
    assert_not Service.exists?(service.id)
  end

  test "staff offers and availability can be created updated and removed" do
    sign_in
    post admin_staff_members_path, params: { staff_member: { first_name: "Maria", last_name: "Lopez" } }
    staff = StaffMember.find_by!(first_name: "Maria")
    assert_redirected_to admin_staff_member_path(staff)
    post admin_service_offerings_path, params: { service_offering: { staff_member_id: staff.id, service_id: @service.id } }
    offering = staff.service_offerings.sole
    assert_redirected_to admin_service_offering_path(offering)
    post admin_availabilities_path, params: { availability: { staff_member_id: staff.id, day_of_week: "monday", start_time: "09:00", end_time: "13:00" } }
    availability = staff.availabilities.sole
    assert_redirected_to admin_availability_path(availability)
    patch admin_availability_path(availability), params: { availability: { end_time: "08:00" } }
    assert_response :unprocessable_entity
    assert_select ".errors", /posterior al inicio/
    patch admin_availability_path(availability), params: { availability: { active: false } }
    assert_not availability.reload.active?
    patch admin_service_offering_path(offering), params: { service_offering: { active: false } }
    assert_not offering.reload.active?
    patch admin_staff_member_path(staff), params: { staff_member: { active: false } }
    assert_not staff.reload.active?
    delete admin_availability_path(availability)
    assert_redirected_to admin_availabilities_path
    delete admin_service_offering_path(offering)
    assert_redirected_to admin_service_offerings_path
    delete admin_staff_member_path(staff)
    assert_redirected_to admin_staff_members_path
  end

  test "customers cannot be promoted and administrators cannot be edited through customer routes" do
    sign_in
    post admin_customers_path, params: { customer: { first_name: "Eva", last_name: "Perez",
      email_address: "eva@example.com", password: "password123", password_confirmation: "password123", role: "admin" } }
    customer = User.find_by!(email_address: "eva@example.com")
    assert_redirected_to admin_customer_path(customer)
    assert customer.customer?
    digest = customer.password_digest
    patch admin_customer_path(customer), params: { customer: { phone: "123", password: "", password_confirmation: "", role: "admin", active: false } }
    assert_redirected_to admin_customer_path(customer)
    assert_equal digest, customer.reload.password_digest
    assert customer.customer?
    assert_not customer.active?
    [ admin_customer_path(@admin), edit_admin_customer_path(@admin) ].each do |path|
      get path
      assert_response :not_found
    end
    patch admin_customer_path(@admin), params: { customer: { active: false } }
    assert_response :not_found
    assert @admin.reload.active?
    delete admin_customer_path(customer)
    assert_redirected_to admin_customers_path
  end

  test "booked records cannot be deleted and errors are shown" do
    sign_in
    appointment = build_appointment
    appointment.save!
    [ admin_customer_path(@customer), admin_service_offering_path(@offering), admin_service_path(@service), admin_staff_member_path(@staff) ].each do |path|
      delete path
      assert_response :unprocessable_entity
      assert_select ".errors"
      assert_no_match(/translation missing/i, response.body)
    end
    delete admin_appointment_path(appointment)
    assert_response :not_found
    assert Appointment.exists?(appointment.id)
  end

  test "reserving rescheduling cancelling and completing follow business rules" do
    sign_in
    attrs = { customer_id: @customer.id, service_offering_id: @offering.id, starts_at: @starts_at.strftime("%Y-%m-%dT%H:%M"), status: "completed" }
    post admin_appointments_path, params: { appointment: attrs }
    appointment = Appointment.sole
    assert_redirected_to admin_appointment_path(appointment)
    assert appointment.scheduled?
    assert_equal @starts_at, appointment.starts_at
    post admin_appointments_path, params: { appointment: attrs }
    assert_response :unprocessable_entity
    assert_select ".errors", /superpone/
    patch complete_admin_appointment_path(appointment)
    assert_response :unprocessable_entity
    patch admin_appointment_path(appointment), params: { appointment: { starts_at: (@starts_at + 1.hour).strftime("%Y-%m-%dT%H:%M"), ends_at: @starts_at, status: "completed" } }
    assert_redirected_to admin_appointment_path(appointment)
    assert_equal @starts_at + 90.minutes, appointment.reload.ends_at
    assert appointment.scheduled?
    travel_to appointment.ends_at
    sign_in
    patch complete_admin_appointment_path(appointment)
    assert_redirected_to admin_appointment_path(appointment)
    assert appointment.reload.completed?
    patch cancel_admin_appointment_path(appointment)
    assert_response :unprocessable_entity
    patch admin_appointment_path(appointment), params: { appointment: { notes: "Atendido" } }
    assert_redirected_to admin_appointment_path(appointment)
    assert_equal "Atendido", appointment.reload.notes
  end

  test "cancellation releases the slot and terminal turns cannot be rescheduled" do
    sign_in
    appointment = build_appointment
    appointment.save!
    patch cancel_admin_appointment_path(appointment)
    assert_redirected_to admin_appointment_path(appointment)
    patch admin_appointment_path(appointment), params: { appointment: { starts_at: @starts_at + 1.hour } }
    assert_response :unprocessable_entity
    assert appointment.reload.cancelled?
    assert build_appointment.save
  end

  test "agenda filters by local date status and staff and handles malformed dates" do
    sign_in
    appointment = build_appointment
    appointment.save!
    get admin_appointments_path, params: { date: @starts_at.to_date.iso8601, status: "scheduled", staff_member_id: @staff.id }
    assert_select "a[href=?]", admin_appointment_path(appointment)
    get admin_appointments_path, params: { status: "cancelled" }
    assert_select "a[href=?]", admin_appointment_path(appointment), count: 0
    get admin_appointments_path, params: { date: "invalid" }
    assert_redirected_to admin_appointments_path
    get admin_appointments_path, params: { status: "invalid" }
    assert_redirected_to admin_appointments_path
  end

  test "lists paginate and user supplied HTML is escaped" do
    sign_in
    26.times { |index| Service.create!(name: "Service #{index}", duration_minutes: 30, price: 10) }
    get admin_services_path
    assert_select "tbody tr", count: 25
    assert_select "a", text: "Siguiente →"
    get admin_services_path, params: { page: 2 }
    assert_select "tbody tr", count: 2
    @service.update!(name: "<script>alert('xss')</script>")
    get admin_service_path(@service)
    assert_no_match(/<script>alert\('xss'\)<\/script>/, response.body)
    assert_includes response.body, "&lt;script&gt;"
  end

  test "login requires a CSRF token when forgery protection is enabled" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    assert_no_difference "AdminSession.count" do
      sign_in
    end
    assert_response :unprocessable_entity
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  private

  def sign_in
    post admin_session_path, params: { session: { email_address: @admin.email_address, password: "password123" } }
  end
end
