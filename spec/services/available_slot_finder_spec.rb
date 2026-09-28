require "rails_helper"

RSpec.describe AvailableSlotFinder do
  include BookingSetup

  before { setup_booking }
  after { travel_back }

  it "returns duration-aligned future slots and removes staff conflicts" do
    @availability.update!(start_time: "09:00", end_time: "11:00")
    AppointmentBooking.save(build_appointment, {})

    slots = described_class.new(@offering, @starts_at.to_date.iso8601).call

    expect(slots.pluck(:starts_at)).to eq([
      @starts_at.change(hour: 9).iso8601,
      @starts_at.change(hour: 9, min: 30).iso8601,
      @starts_at.change(hour: 10, min: 30).iso8601
    ])
  end

  it "rejects malformed and impossible dates" do
    expect { described_class.new(@offering, "tomorrow") }.to raise_error(described_class::InvalidDate)
    expect { described_class.new(@offering, "2030-02-30") }.to raise_error(described_class::InvalidDate)
  end
end
