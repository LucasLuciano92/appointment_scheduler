require "rails_helper"

RSpec.describe ServiceOffering, type: :model do
  include BookingSetup

  before { setup_booking }

  it "connects staff services customers and appointments" do
    appointment = build_appointment
    appointment.save!

    expect(@staff.services).to include(@service)
    expect(@service.staff_members).to include(@staff)
    expect(@customer.appointments).to include(appointment)
    expect(@offering.appointments).to include(appointment)
    expect(appointment.staff_member).to eq(@staff)
  end

  it "requires associations unique pairs and boolean activation" do
    offering = described_class.new(active: nil)

    expect(offering).not_to be_valid
    expect(offering.errors).to include(:staff_member, :service, :active)
    offering.assign_attributes(staff_member: @staff, service: @service, active: true)
    expect(offering).not_to be_valid
    expect(offering.errors[:service_id]).to be_present
    expect do
      described_class.insert_all!([ @offering.attributes.except("id") ])
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "preserves identity and related history for booked offerings" do
    build_appointment.save!
    other_service = Service.create!(name: "Color", duration_minutes: 60, price: 200)

    expect(@offering.update(service: other_service)).to be(false)
    @offering.reload
    expect(@offering.destroy).to be(false)
    expect(@customer.destroy).to be(false)
    expect(@staff.destroy).to be(false)
    expect(@service.destroy).to be(false)
    expect(@offering.update(active: false)).to be(true)
  end

  it "removes unbooked offerings before their catalog entries" do
    expect(@offering.destroy).to be_truthy
    expect(@service.destroy).to be_truthy
    expect(@staff.destroy).to be_truthy
  end
end
