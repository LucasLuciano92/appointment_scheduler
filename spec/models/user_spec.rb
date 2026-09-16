require "rails_helper"

RSpec.describe User, type: :model do
  it "normalizes email and securely authenticates passwords" do
    user = described_class.create!(first_name: "Ana", last_name: "Perez",
      email_address: " ANA@Example.com ", password: "password123")

    expect(user.reload.email_address).to eq("ana@example.com")
    expect(user).to be_customer
    expect(user).to be_active
    expect(user.authenticate("password123")).to eq(user)
    expect(user.authenticate("wrongpassword")).to be_falsey
    expect(user.password_digest).not_to eq("password123")
    expect(user.update(phone: "123")).to be(true)
  end

  it "requires identity password valid role and boolean activation" do
    user = described_class.new(role: :unknown, active: nil, password: "short")

    expect(user).not_to be_valid
    expect(user.errors).to include(:first_name, :last_name, :email_address, :role, :active, :password)
    expect(described_class.new(first_name: "Ana", last_name: "Perez", email_address: "a@example.com")).not_to be_valid
  end

  it "rejects malformed and duplicate emails in the model and database" do
    user = described_class.create!(first_name: "Ana", last_name: "Perez",
      email_address: "ana@example.com", password: "password123")
    duplicate = user.dup
    duplicate.password = "password123"
    duplicate.email_address = "ANA@EXAMPLE.COM"

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email_address]).to be_present
    duplicate.email_address = "invalid"
    expect(duplicate).not_to be_valid
    expect do
      described_class.insert_all!([ user.attributes.except("id").merge("email_address" => "ANA@EXAMPLE.COM") ])
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
