require "rails_helper"
require "stringio"

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

  it "accepts catalog images in supported formats up to five megabytes" do
    service = described_class.new(name: "Color", duration_minutes: 60, price: 200)
    service.image.attach(io: StringIO.new("image data"), filename: "color.webp", content_type: "image/webp")

    expect(service).to be_valid
  end

  it "rejects unsupported or oversized catalog images" do
    service = described_class.new(name: "Color", duration_minutes: 60, price: 200)
    service.image.attach(io: StringIO.new("document"), filename: "instructions.pdf",
      content_type: "application/pdf")

    expect(service).not_to be_valid
    expect(service.errors[:image]).to include("debe ser JPEG, PNG o WebP")

    service.image.attach(io: StringIO.new("x" * (described_class::MAX_IMAGE_SIZE + 1)),
      filename: "large.png", content_type: "image/png")
    expect(service).not_to be_valid
    expect(service.errors[:image]).to include("debe pesar 5 MB o menos")
  end
end
