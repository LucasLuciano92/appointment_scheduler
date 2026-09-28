require "rails_helper"

RSpec.describe ApiSession do
  let(:customer) do
    User.create!(first_name: "Ana", last_name: "Perez", email_address: "ana@example.com",
      password: "password123")
  end

  it "issues a token while persisting only its digest" do
    api_session, token = described_class.issue!(customer)

    expect(token).to be_present
    expect(api_session.token_digest).not_to eq(token)
    expect(described_class.authenticate(token)).to eq(api_session)
  end

  it "rejects expired sessions and sessions for customers without access" do
    expired, token = described_class.issue!(customer)
    expired.update!(expires_at: 1.minute.ago)
    expect(described_class.authenticate(token)).to be_nil

    active_session, = described_class.issue!(customer)
    customer.update!(active: false)
    expect { active_session.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
