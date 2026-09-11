module BookingSetup
  def setup_booking
    travel_to Time.zone.local(2030, 1, 7, 8)
    @customer = User.create!(first_name: "Ana", last_name: "Perez",
      email_address: "ana@example.com", password: "password123")
    @staff = StaffMember.create!(first_name: "Laura", last_name: "Gomez")
    @service = Service.create!(name: "Haircut", duration_minutes: 30, price: 15000)
    @offering = ServiceOffering.create!(staff_member: @staff, service: @service)
    @starts_at = 1.day.from_now.change(hour: 10)
    @availability = @staff.availabilities.create!(
      day_of_week: @starts_at.wday, start_time: "09:00", end_time: "18:00")
  end

  def build_appointment(**attributes)
    Appointment.new(customer: @customer, service_offering: @offering,
      starts_at: @starts_at, **attributes)
  end
end
