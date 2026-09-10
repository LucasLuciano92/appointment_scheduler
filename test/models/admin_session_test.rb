require "test_helper"

class AdminSessionTest < ActiveSupport::TestCase
  test "requires an owner and expiration" do
    session = AdminSession.new
    assert_not session.valid?
    assert session.errors[:user].any?
    assert session.errors[:expires_at].any?
  end
end
