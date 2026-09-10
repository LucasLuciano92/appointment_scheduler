require "test_helper"

class StaffMemberTest < ActiveSupport::TestCase
  test "requires names and activation but permits missing contact information" do
    staff = StaffMember.new
    assert_not staff.valid?
    assert staff.errors[:first_name].any?
    assert staff.errors[:last_name].any?
    staff.assign_attributes(first_name: "Laura", last_name: "Gomez", email_address: " ")
    assert staff.save
    assert_nil staff.reload.email_address
    assert StaffMember.create!(first_name: "Maria", last_name: "Perez").active?
    staff.active = nil
    assert_not staff.valid?
  end

  test "normalizes and validates optional unique email" do
    StaffMember.create!(first_name: "Laura", last_name: "Gomez", email_address: "Laura@example.com")
    staff = StaffMember.new(first_name: "Maria", last_name: "Perez", email_address: " LAURA@EXAMPLE.COM ")
    assert_not staff.valid?
    assert staff.errors[:email_address].any?
    staff.email_address = "invalid"
    assert_not staff.valid?
  end

  test "deleting staff without offerings removes its weekly availability" do
    staff = StaffMember.create!(first_name: "Laura", last_name: "Gomez")
    staff.availabilities.create!(day_of_week: :monday, start_time: "09:00", end_time: "12:00")
    assert_difference "Availability.count", -1 do
      assert staff.destroy
    end
  end
end
