require "rails_helper"

RSpec.describe Service, type: :model do
  it "accepts a free service with positive integer duration" do
    service = described_class.new(name: " Consultation ", duration_minutes: 30, price: 0)

    expect(service.save).to be(true)
    expect(service.reload.name).to eq("Consultation")
    expect(service).to be_active
  end

  it "rejects missing name invalid duration negative price and nil activation" do
    service = described_class.new(name: " ", duration_minutes: 0, price: -1, active: nil)

    expect(service).not_to be_valid
    expect(service.errors).to include(:name, :duration_minutes, :price, :active)
    service.duration_minutes = 1.5
    expect(service).not_to be_valid
    expect(service.errors[:duration_minutes]).to be_present
  end

  it "enforces unique names and valid numeric values in the model and database" do
    service = described_class.create!(name: "Haircut", duration_minutes: 30, price: 100)
    duplicate = described_class.new(name: " HAIRCUT ", duration_minutes: 60, price: 200)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:name]).to be_present
    expect { service.update_columns(duration_minutes: 0) }.to raise_error(ActiveRecord::StatementInvalid)
    expect { service.update_columns(price: -1) }.to raise_error(ActiveRecord::StatementInvalid)
    service.reload
    expect do
      described_class.insert_all!([ service.attributes.except("id").merge("name" => "HAIRCUT") ])
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
