require "rails_helper"

RSpec.describe Availability, type: :model do
  include BookingSetup

  before { setup_booking }

  it "requires staff day times and boolean activation" do
    availability = described_class.new(day_of_week: :unknown, active: nil)

    expect(availability).not_to be_valid
    expect(availability.errors).to include(:staff_member, :day_of_week, :start_time, :end_time, :active)
  end

  it "rejects reversed equal and overnight hours" do
    [ [ "18:00", "09:00" ], [ "09:00", "09:00" ], [ "23:00", "01:00" ] ].each do |start_time, end_time|
      @availability.assign_attributes(start_time: start_time, end_time: end_time)
      expect(@availability).not_to be_valid
      expect(@availability.errors[:end_time]).to be_present
    end
  end

  it "rejects overlapping active windows including reactivation" do
    duplicate = @availability.dup

    expect(duplicate).not_to be_valid
    duplicate.active = false
    duplicate.save!
    expect(duplicate.update(active: true)).to be(false)
    expect(@availability.update(start_time: "08:00")).to be(true)
  end

  it "allows adjacent windows and independent staff or days" do
    adjacent = @availability.dup
    adjacent.assign_attributes(start_time: "18:00", end_time: "20:00")
    other_day = @availability.dup
    other_day.day_of_week = :wednesday
    other_staff = @availability.dup
    other_staff.staff_member = StaffMember.create!(first_name: "Maria", last_name: "Perez")

    expect(adjacent.save).to be(true)
    expect(other_day.save).to be(true)
    expect(other_staff.save).to be(true)
  end

  it "compares UTC appointments against local weekly hours" do
    expect(@availability.reload.start_time.hour).to eq(9)
    expect(@availability.covers?(@starts_at.utc, (@starts_at + 30.minutes).utc)).to be(true)
    expect(@availability.covers?(@starts_at.change(hour: 8), @starts_at)).to be(false)
    expect(@availability.covers?(@starts_at, @starts_at + 1.day)).to be(false)
  end

  it "rejects invalid weekdays and reversed times in the database" do
    expect { @availability.update_columns(day_of_week: 7) }.to raise_error(ActiveRecord::StatementInvalid)
    expect do
      @availability.update_columns(start_time: "19:00", end_time: "09:00")
    end.to raise_error(ActiveRecord::StatementInvalid)
  end
end
