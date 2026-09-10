require "test_helper"
require_relative "../support/booking_setup"

class AppointmentBookingTest < ActiveSupport::TestCase
  include BookingSetup
  self.use_transactional_tests = false

  setup { setup_booking }

  teardown do
    if @staff&.persisted?
      Appointment.where(service_offering_id: @staff.service_offerings.select(:id)).delete_all
      ServiceOffering.where(staff_member_id: @staff.id).delete_all
      Availability.where(staff_member_id: @staff.id).delete_all
      @staff.delete
    end
    @other_service&.delete
    @service&.delete
    @customer&.delete
  end

  test "concurrent creates for the same staff permit only one overlapping reservation" do
    @other_service = Service.create!(name: "Color", duration_minutes: 60, price: 200)
    other_offering = ServiceOffering.create!(staff_member: @staff, service: @other_service)
    results = concurrently([ @offering.id, other_offering.id ]) do |offering_id|
      appointment = Appointment.new
      saved = AppointmentBooking.save(appointment, customer_id: @customer.id,
        service_offering_id: offering_id, starts_at: @starts_at)
      saved ? :saved : appointment.errors.details[:base].first[:error]
    end
    assert_equal [ :overlapping_appointment, :saved ], results.sort
    assert_equal 1, @staff.appointments.count
  end

  test "concurrent rescheduling into the same slot permits only one change" do
    first = build_appointment(starts_at: @starts_at - 1.hour)
    first.save!
    second = build_appointment(starts_at: @starts_at + 1.hour)
    second.save!
    results = concurrently([ first.id, second.id ]) do |appointment_id|
      appointment = Appointment.find(appointment_id)
      saved = AppointmentBooking.save(appointment, starts_at: @starts_at)
      saved ? :saved : appointment.errors.details[:base].first[:error]
    end
    assert_equal [ :overlapping_appointment, :saved ], results.sort
    assert_equal 1, @staff.appointments.where(starts_at: @starts_at).count
    assert_equal 2, @staff.appointments.count
  end

  private

  def concurrently(values, &operation)
    ready = Queue.new
    start = Queue.new
    workers = values.map do |value|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          operation.call(value)
        end
      end
    end
    values.size.times { ready.pop }
    values.size.times { start << true }
    workers.map(&:value)
  end
end
