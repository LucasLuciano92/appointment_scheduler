class DemoDataSetup
  class ProductionEnvironmentError < StandardError; end

  Result = Data.define(:admin, :customer, :service, :staff_member, :service_offering)

  def self.call(admin_password:, customer_password:)
    raise ProductionEnvironmentError, "Los datos demo no se pueden crear en producción." if Rails.env.production?

    new(admin_password:, customer_password:).call
  end

  def initialize(admin_password:, customer_password:)
    @admin_password = admin_password
    @customer_password = customer_password
  end

  def call
    ApplicationRecord.transaction do
      admin = prepare_user(
        email_address: "admin.demo@example.com", first_name: "Ada", last_name: "Admin",
        password: admin_password, role: :admin
      )
      customer = prepare_user(
        email_address: "cliente.demo@example.com", first_name: "Ana", last_name: "Cliente",
        password: customer_password, role: :customer
      )
      service = prepare_service
      staff_member = prepare_staff_member
      service_offering = ServiceOffering.find_or_initialize_by(service:, staff_member:)
      service_offering.update!(active: true)
      prepare_availabilities(staff_member)

      Result.new(admin:, customer:, service:, staff_member:, service_offering:)
    end
  end

  private

  attr_reader :admin_password, :customer_password

  def prepare_user(email_address:, first_name:, last_name:, password:, role:)
    user = User.find_or_initialize_by(email_address:)
    user.assign_attributes(first_name:, last_name:, password:, password_confirmation: password, role:, active: true)
    user.save!
    user
  end

  def prepare_service
    service = Service.find_or_initialize_by(name: "Corte demo")
    service.update!(
      description: "Servicio preparado para probar la integración del TP2.",
      duration_minutes: 30, price: 15_000, active: true
    )
    service
  end

  def prepare_staff_member
    staff_member = StaffMember.find_or_initialize_by(email_address: "profesional.demo@example.com")
    staff_member.update!(first_name: "Laura", last_name: "Profesional", active: true)
    staff_member
  end

  def prepare_availabilities(staff_member)
    Availability.day_of_weeks.slice("monday", "tuesday", "wednesday", "thursday", "friday").each_key do |day|
      availability = staff_member.availabilities.find_or_initialize_by(day_of_week: day)
      availability.update!(start_time: "09:00", end_time: "18:00", active: true)
    end
  end
end
