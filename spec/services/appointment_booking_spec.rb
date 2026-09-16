require "rails_helper"
require "timeout"

RSpec.describe AppointmentBooking, type: :service do
  include BookingSetup

  self.use_transactional_tests = false

  before { setup_booking }

  after do
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

  it "permits only one overlapping reservation during concurrent creates for the same staff" do
    @other_service = Service.create!(name: "Color", duration_minutes: 60, price: 200)
    other_offering = ServiceOffering.create!(staff_member: @staff, service: @other_service)
    results = concurrently([ @offering.id, other_offering.id ]) do |offering_id|
      appointment = Appointment.new
      saved = described_class.save(appointment, customer_id: @customer.id,
        service_offering_id: offering_id, starts_at: @starts_at)
      saved ? :saved : appointment.errors.details[:base].first[:error]
    end

    expect(results).to contain_exactly(:overlapping_appointment, :saved)
    expect(@staff.appointments.count).to eq(1)
  end

  it "permits only one concurrent rescheduling into the same slot" do
    first = build_appointment(starts_at: @starts_at - 1.hour)
    first.save!
    second = build_appointment(starts_at: @starts_at + 1.hour)
    second.save!
    results = concurrently([ first.id, second.id ]) do |appointment_id|
      appointment = Appointment.find(appointment_id)
      saved = described_class.save(appointment, starts_at: @starts_at)
      saved ? :saved : appointment.errors.details[:base].first[:error]
    end

    expect(results).to contain_exactly(:overlapping_appointment, :saved)
    expect(@staff.appointments.where(starts_at: @starts_at).count).to eq(1)
    expect(@staff.appointments.count).to eq(2)
  end

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
    Timeout.timeout(10) do
      values.size.times { ready.pop }
      values.size.times { start << true }
      workers.map(&:value)
    end
  ensure
    workers&.each do |worker|
      worker.kill if worker.alive?
      worker.join
    end
  end
end
