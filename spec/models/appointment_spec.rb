require "rails_helper"

RSpec.describe Appointment, type: :model do
  include BookingSetup

  before { setup_booking }

  it "preloads agenda details without lazy queries per appointment" do
    appointment = build_appointment
    appointment.save!
    record = described_class.with_booking_details.strict_loading.find(appointment.id)

    expect(record.customer).to eq(@customer)
    expect(record.staff_member).to eq(@staff)
    expect(record.service).to eq(@service)
  end

  it "creates a scheduled appointment and calculates its end" do
    appointment = build_appointment

    appointment.save!
    expect(appointment.reload).to be_scheduled
    expect(appointment.ends_at).to eq(@starts_at + 30.minutes)
  end

  it "requires associations dates and valid status without raising on missing data" do
    appointment = described_class.new(status: :unknown)

    expect(appointment).not_to be_valid
    expect(appointment.errors).to include(:customer, :service_offering, :starts_at, :ends_at, :status)
  end

  it "rejects administrators inactive customers and inactive catalog entries" do
    @customer.update!(role: :admin)
    expect(build_appointment).not_to be_valid
    @customer.reload
    @offering.reload
    @customer.update!(role: :customer, active: false)
    expect(build_appointment).not_to be_valid
    @customer.reload
    @offering.reload
    @customer.update!(active: true)

    [ @staff, @service, @offering ].each do |record|
      record.update!(active: false)
      expect(build_appointment).not_to be_valid
      @customer.reload
      @offering.reload
      record.update!(active: true)
    end
  end

  it "rejects past and present starts" do
    [ Time.current, 1.minute.ago ].each do |starts_at|
      appointment = build_appointment(starts_at: starts_at)

      expect(appointment).not_to be_valid
      expect(appointment.errors[:starts_at]).to be_present
    end
  end

  it "must fit fully in one active availability" do
    expect(build_appointment(starts_at: @starts_at.change(hour: 9))).to be_valid
    expect(build_appointment(starts_at: @starts_at.change(hour: 17, min: 30))).to be_valid
    expect(build_appointment(starts_at: @starts_at.change(hour: 17, min: 45))).not_to be_valid
    expect(build_appointment(starts_at: @starts_at + 1.day)).not_to be_valid
    @availability.update!(active: false)
    expect(build_appointment).not_to be_valid
  end

  it "cannot span adjacent windows or cross midnight" do
    @availability.update!(end_time: "10:15")
    @staff.availabilities.create!(day_of_week: @starts_at.wday, start_time: "10:15", end_time: "18:00")

    expect(build_appointment).not_to be_valid
    @service.update!(duration_minutes: 24 * 60)
    expect(build_appointment).not_to be_valid
  end

  it "rejects overlapping turns across different services of the same staff" do
    build_appointment.save!
    other_service = Service.create!(name: "Color", duration_minutes: 60, price: 200)
    other_offering = ServiceOffering.create!(staff_member: @staff, service: other_service)

    [ @starts_at - 15.minutes, @starts_at, @starts_at + 15.minutes ].each do |starts_at|
      appointment = build_appointment(starts_at: starts_at)
      expect(appointment).not_to be_valid
      expect(appointment.errors[:base]).to include("overlaps another scheduled appointment")
    end
    expect(build_appointment(service_offering: other_offering, starts_at: @starts_at - 30.minutes)).not_to be_valid
  end

  it "allows adjacent appointments and simultaneous turns for different staff" do
    build_appointment.save!
    other_staff = StaffMember.create!(first_name: "Maria", last_name: "Perez")
    other_staff.availabilities.create!(day_of_week: @starts_at.wday, start_time: "09:00", end_time: "18:00")
    offering = ServiceOffering.create!(staff_member: other_staff, service: @service)

    expect(build_appointment(starts_at: @starts_at - 30.minutes).save).to be(true)
    expect(build_appointment(starts_at: @starts_at + 30.minutes).save).to be(true)
    expect(build_appointment(service_offering: offering).save).to be(true)
  end

  it "frees the slot on cancellation and treats cancellation as terminal" do
    appointment = build_appointment
    appointment.save!

    expect(appointment.update(status: :cancelled)).to be(true)
    expect(build_appointment.save).to be(true)
    expect(appointment.update(status: :scheduled)).to be(false)
    appointment.reload
    expect(appointment.update(starts_at: @starts_at + 1.hour)).to be(false)
  end

  it "completes only finished scheduled appointments" do
    appointment = build_appointment
    appointment.save!

    expect(appointment.update(status: :completed)).to be(false)
    appointment.reload
    travel_to appointment.ends_at
    expect(appointment.update(status: :completed)).to be(true)
    expect(appointment.update(status: :cancelled)).to be(false)
    expect(build_appointment(status: :completed)).not_to be_valid
    expect(build_appointment(status: :cancelled)).not_to be_valid
  end

  it "preserves duration on catalog changes and refreshes it on rescheduling" do
    appointment = build_appointment
    appointment.save!
    original_end = appointment.ends_at
    @service.update!(duration_minutes: 60)

    expect(appointment.update(notes: "Keep the agreed duration")).to be(true)
    expect(appointment.reload.ends_at).to eq(original_end)
    expect(appointment.update(starts_at: @starts_at + 1.hour)).to be(true)
    expect(appointment.reload.ends_at).to eq(@starts_at + 2.hours)
    expect(appointment.update(ends_at: appointment.ends_at + 1.minute)).to be(false)
  end

  it "rejects rescheduling to occupied slots and past dates" do
    appointment = build_appointment
    appointment.save!
    build_appointment(starts_at: @starts_at + 1.hour).save!

    expect(appointment.update(starts_at: @starts_at + 1.hour)).to be(false)
    appointment.reload
    expect(appointment.update(starts_at: 1.day.ago)).to be(false)
  end

  it "preserves history and permits annotation or cancellation after deactivation" do
    appointment = build_appointment
    appointment.save!
    [ @customer, @staff, @service, @offering, @availability ].each { |record| record.update!(active: false) }
    travel_to @starts_at + 1.day

    expect(appointment.update(notes: "Historical note")).to be(true)
    expect(appointment.update(status: :cancelled)).to be(true)
    expect(described_class.count).to eq(1)
    expect(appointment.destroy).to be(false)
    expect(described_class.exists?(appointment.id)).to be(true)
  end

  it "enforces foreign keys status and date ordering in the database" do
    appointment = build_appointment
    appointment.save!

    expect { appointment.update_columns(customer_id: -1) }.to raise_error(ActiveRecord::InvalidForeignKey)
    expect { appointment.update_columns(status: 9) }.to raise_error(ActiveRecord::StatementInvalid)
    expect { appointment.update_columns(ends_at: @starts_at - 1.minute) }.to raise_error(ActiveRecord::StatementInvalid)
  end
end
