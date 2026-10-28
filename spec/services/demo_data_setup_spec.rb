require "rails_helper"

RSpec.describe DemoDataSetup do
  it "creates a complete idempotent data set for the integrated demo" do
    first = described_class.call(admin_password: "admin-pass-123", customer_password: "customer-pass-123")
    second = described_class.call(admin_password: "admin-pass-123", customer_password: "customer-pass-123")

    expect(second).to eq(first)
    expect(first.admin).to be_admin
    expect(first.customer).to be_customer
    expect(first.service_offering).to be_active
    expect(first.staff_member.availabilities.active.count).to eq(5)
    expect(User.where(email_address: [ first.admin.email_address, first.customer.email_address ]).count).to eq(2)
    expect(Service.where(name: first.service.name).count).to eq(1)
  end

  it "rejects weak demo credentials without leaving partial data" do
    expect do
      described_class.call(admin_password: "short", customer_password: "short")
    end.to raise_error(ActiveRecord::RecordInvalid)

    expect(User.where(email_address: [ "admin.demo@example.com", "cliente.demo@example.com" ])).to be_empty
    expect(Service.where(name: "Corte demo")).to be_empty
  end

  it "refuses to create demo accounts in production" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("production"))

    expect do
      described_class.call(admin_password: "admin-pass-123", customer_password: "customer-pass-123")
    end.to raise_error(described_class::ProductionEnvironmentError)
  end
end
