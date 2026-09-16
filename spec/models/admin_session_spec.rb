require "rails_helper"

RSpec.describe AdminSession, type: :model do
  it "requires an owner and expiration" do
    session = described_class.new

    expect(session).not_to be_valid
    expect(session.errors[:user]).to be_present
    expect(session.errors[:expires_at]).to be_present
  end
end
