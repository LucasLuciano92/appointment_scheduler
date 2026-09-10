require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email and securely authenticates passwords" do
    user = User.create!(first_name: "Ana", last_name: "Perez",
      email_address: " ANA@Example.com ", password: "password123")
    assert_equal "ana@example.com", user.reload.email_address
    assert user.customer?
    assert user.active?
    assert_equal user, user.authenticate("password123")
    assert_not user.authenticate("wrongpassword")
    assert_not_equal "password123", user.password_digest
    assert user.update(phone: "123")
  end

  test "requires identity password valid role and boolean activation" do
    user = User.new(role: :unknown, active: nil, password: "short")
    assert_not user.valid?
    %i[first_name last_name email_address role active password].each do |attribute|
      assert user.errors[attribute].any?, attribute.to_s
    end
    assert_not User.new(first_name: "Ana", last_name: "Perez", email_address: "a@example.com").valid?
  end

  test "rejects malformed and duplicate emails in the model and database" do
    user = User.create!(first_name: "Ana", last_name: "Perez",
      email_address: "ana@example.com", password: "password123")
    duplicate = user.dup
    duplicate.password = "password123"
    duplicate.email_address = "ANA@EXAMPLE.COM"
    assert_not duplicate.valid?
    assert duplicate.errors[:email_address].any?
    duplicate.email_address = "invalid"
    assert_not duplicate.valid?
    assert_raises ActiveRecord::RecordNotUnique do
      User.insert_all!([ user.attributes.except("id").merge("email_address" => "ANA@EXAMPLE.COM") ])
    end
  end
end
