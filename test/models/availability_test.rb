require "test_helper"
require_relative "../support/booking_setup"

class AvailabilityTest < ActiveSupport::TestCase
  include BookingSetup
  setup { setup_booking }

  test "requires staff day times and boolean activation" do
    availability = Availability.new(day_of_week: :unknown, active: nil)
    assert_not availability.valid?
    %i[staff_member day_of_week start_time end_time active].each do |attribute|
      assert availability.errors[attribute].any?, attribute.to_s
    end
  end

  test "rejects reversed equal and overnight hours" do
    [ [ "18:00", "09:00" ], [ "09:00", "09:00" ], [ "23:00", "01:00" ] ].each do |start_time, end_time|
      @availability.assign_attributes(start_time: start_time, end_time: end_time)
      assert_not @availability.valid?
      assert @availability.errors[:end_time].any?
    end
  end

  test "rejects overlapping active windows including reactivation" do
    duplicate = @availability.dup
    assert_not duplicate.valid?
    duplicate.active = false
    duplicate.save!
    assert_not duplicate.update(active: true)
    assert @availability.update(start_time: "08:00")
  end

  test "allows adjacent windows and independent staff or days" do
    adjacent = @availability.dup
    adjacent.assign_attributes(start_time: "18:00", end_time: "20:00")
    assert adjacent.save
    other_day = @availability.dup
    other_day.day_of_week = :wednesday
    assert other_day.save
    other_staff = @availability.dup
    other_staff.staff_member = StaffMember.create!(first_name: "Maria", last_name: "Perez")
    assert other_staff.save
  end

  test "compares UTC appointments against local weekly hours" do
    assert_equal 9, @availability.reload.start_time.hour
    assert @availability.covers?(@starts_at.utc, (@starts_at + 30.minutes).utc)
    assert_not @availability.covers?(@starts_at.change(hour: 8), @starts_at)
    assert_not @availability.covers?(@starts_at, @starts_at + 1.day)
  end

  test "database rejects invalid weekdays and reversed times" do
    assert_raises(ActiveRecord::StatementInvalid) { @availability.update_columns(day_of_week: 7) }
    assert_raises ActiveRecord::StatementInvalid do
      @availability.update_columns(start_time: "19:00", end_time: "09:00")
    end
  end
end
