require "rails_helper"

RSpec.describe StaffMember, type: :model do
  it "requires names and activation but permits missing contact information" do
    staff = described_class.new

    expect(staff).not_to be_valid
    expect(staff.errors).to include(:first_name, :last_name)
    staff.assign_attributes(first_name: "Laura", last_name: "Gomez", email_address: " ")
    expect(staff.save).to be(true)
    expect(staff.reload.email_address).to be_nil
    expect(described_class.create!(first_name: "Maria", last_name: "Perez")).to be_active
    staff.active = nil
    expect(staff).not_to be_valid
  end

  it "normalizes and validates optional unique email" do
    described_class.create!(first_name: "Laura", last_name: "Gomez", email_address: "Laura@example.com")
    staff = described_class.new(first_name: "Maria", last_name: "Perez", email_address: " LAURA@EXAMPLE.COM ")

    expect(staff).not_to be_valid
    expect(staff.errors[:email_address]).to be_present
    staff.email_address = "invalid"
    expect(staff).not_to be_valid
  end

  it "deletes weekly availability when staff has no offerings" do
    staff = described_class.create!(first_name: "Laura", last_name: "Gomez")
    staff.availabilities.create!(day_of_week: :monday, start_time: "09:00", end_time: "12:00")

    expect { expect(staff.destroy).to be_truthy }.to change(Availability, :count).by(-1)
  end
end
