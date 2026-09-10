require "test_helper"
require_relative "../support/booking_setup"

class ServiceOfferingTest < ActiveSupport::TestCase
  include BookingSetup
  setup { setup_booking }

  test "connects staff services customers and appointments" do
    appointment = build_appointment
    appointment.save!
    assert_includes @staff.services, @service
    assert_includes @service.staff_members, @staff
    assert_includes @customer.appointments, appointment
    assert_includes @offering.appointments, appointment
    assert_equal @staff, appointment.staff_member
  end

  test "requires associations unique pairs and boolean activation" do
    offering = ServiceOffering.new(active: nil)
    assert_not offering.valid?
    %i[staff_member service active].each { |attribute| assert offering.errors[attribute].any? }
    offering.assign_attributes(staff_member: @staff, service: @service, active: true)
    assert_not offering.valid?
    assert offering.errors[:service_id].any?
    assert_raises ActiveRecord::RecordNotUnique do
      ServiceOffering.insert_all!([ @offering.attributes.except("id") ])
    end
  end

  test "booked offerings preserve identity and related history" do
    build_appointment.save!
    other_service = Service.create!(name: "Color", duration_minutes: 60, price: 200)
    assert_not @offering.update(service: other_service)
    @offering.reload
    assert_not @offering.destroy
    assert_not @customer.destroy
    assert_not @staff.destroy
    assert_not @service.destroy
    assert @offering.update(active: false)
  end

  test "unbooked offerings can be removed before their catalog entries" do
    assert @offering.destroy
    assert @service.destroy
    assert @staff.destroy
  end
end
