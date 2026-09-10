require "test_helper"
require_relative "../support/booking_setup"

class AppointmentTest < ActiveSupport::TestCase
  include BookingSetup
  setup { setup_booking }

  test "creates a scheduled appointment and calculates its end" do
    appointment = build_appointment
    appointment.save!
    assert appointment.reload.scheduled?
    assert_equal @starts_at + 30.minutes, appointment.ends_at
  end

  test "requires associations dates and valid status without raising on missing data" do
    appointment = Appointment.new(status: :unknown)
    assert_not appointment.valid?
    %i[customer service_offering starts_at ends_at status].each do |attribute|
      assert appointment.errors[attribute].any?, attribute.to_s
    end
  end

  test "rejects administrators inactive customers and inactive catalog entries" do
    @customer.update!(role: :admin)
    assert_not build_appointment.valid?
    @customer.reload
    @offering.reload
    @customer.update!(role: :customer, active: false)
    assert_not build_appointment.valid?
    @customer.reload
    @offering.reload
    @customer.update!(active: true)
    [ @staff, @service, @offering ].each do |record|
      record.update!(active: false)
      assert_not build_appointment.valid?
      @customer.reload
      @offering.reload
      record.update!(active: true)
    end
  end

  test "rejects past and present starts" do
    [ Time.current, 1.minute.ago ].each do |starts_at|
      appointment = build_appointment(starts_at: starts_at)
      assert_not appointment.valid?
      assert appointment.errors[:starts_at].any?
    end
  end

  test "must fit fully in one active availability" do
    assert build_appointment(starts_at: @starts_at.change(hour: 9)).valid?
    assert build_appointment(starts_at: @starts_at.change(hour: 17, min: 30)).valid?
    assert_not build_appointment(starts_at: @starts_at.change(hour: 17, min: 45)).valid?
    assert_not build_appointment(starts_at: @starts_at + 1.day).valid?
    @availability.update!(active: false)
    assert_not build_appointment.valid?
  end

  test "cannot span adjacent windows or cross midnight" do
    @availability.update!(end_time: "10:15")
    @staff.availabilities.create!(day_of_week: @starts_at.wday, start_time: "10:15", end_time: "18:00")
    assert_not build_appointment.valid?
    @service.update!(duration_minutes: 24 * 60)
    assert_not build_appointment.valid?
  end

  test "rejects overlapping turns across different services of the same staff" do
    build_appointment.save!
    other_service = Service.create!(name: "Color", duration_minutes: 60, price: 200)
    other_offering = ServiceOffering.create!(staff_member: @staff, service: other_service)
    [ @starts_at - 15.minutes, @starts_at, @starts_at + 15.minutes ].each do |starts_at|
      appointment = build_appointment(starts_at: starts_at)
      assert_not appointment.valid?
      assert_includes appointment.errors[:base], "overlaps another scheduled appointment"
    end
    assert_not build_appointment(service_offering: other_offering, starts_at: @starts_at - 30.minutes).valid?
  end

  test "allows adjacent appointments and simultaneous turns for different staff" do
    build_appointment.save!
    assert build_appointment(starts_at: @starts_at - 30.minutes).save
    assert build_appointment(starts_at: @starts_at + 30.minutes).save
    other_staff = StaffMember.create!(first_name: "Maria", last_name: "Perez")
    other_staff.availabilities.create!(day_of_week: @starts_at.wday, start_time: "09:00", end_time: "18:00")
    offering = ServiceOffering.create!(staff_member: other_staff, service: @service)
    assert build_appointment(service_offering: offering).save
  end

  test "cancellation frees the slot and is terminal" do
    appointment = build_appointment
    appointment.save!
    assert appointment.update(status: :cancelled)
    assert build_appointment.save
    assert_not appointment.update(status: :scheduled)
    appointment.reload
    assert_not appointment.update(starts_at: @starts_at + 1.hour)
  end

  test "only finished scheduled appointments can be completed" do
    appointment = build_appointment
    appointment.save!
    assert_not appointment.update(status: :completed)
    appointment.reload
    travel_to appointment.ends_at
    assert appointment.update(status: :completed)
    assert_not appointment.update(status: :cancelled)
    assert_not build_appointment(status: :completed).valid?
    assert_not build_appointment(status: :cancelled).valid?
  end

  test "preserves duration on catalog changes and refreshes it on rescheduling" do
    appointment = build_appointment
    appointment.save!
    original_end = appointment.ends_at
    @service.update!(duration_minutes: 60)
    assert appointment.update(notes: "Keep the agreed duration")
    assert_equal original_end, appointment.reload.ends_at
    assert appointment.update(starts_at: @starts_at + 1.hour)
    assert_equal @starts_at + 2.hours, appointment.reload.ends_at
    assert_not appointment.update(ends_at: appointment.ends_at + 1.minute)
  end

  test "rescheduling rejects occupied slots and past dates" do
    appointment = build_appointment
    appointment.save!
    build_appointment(starts_at: @starts_at + 1.hour).save!
    assert_not appointment.update(starts_at: @starts_at + 1.hour)
    appointment.reload
    assert_not appointment.update(starts_at: 1.day.ago)
  end

  test "preserves history and permits annotation or cancellation after deactivation" do
    appointment = build_appointment
    appointment.save!
    [ @customer, @staff, @service, @offering, @availability ].each { |record| record.update!(active: false) }
    travel_to @starts_at + 1.day
    assert appointment.update(notes: "Historical note")
    assert appointment.update(status: :cancelled)
    assert_equal 1, Appointment.count
    assert_not appointment.destroy
    assert Appointment.exists?(appointment.id)
  end

  test "database enforces foreign keys status and date ordering" do
    appointment = build_appointment
    appointment.save!
    assert_raises(ActiveRecord::InvalidForeignKey) { appointment.update_columns(customer_id: -1) }
    assert_raises(ActiveRecord::StatementInvalid) { appointment.update_columns(status: 9) }
    assert_raises(ActiveRecord::StatementInvalid) { appointment.update_columns(ends_at: @starts_at - 1.minute) }
  end
end
