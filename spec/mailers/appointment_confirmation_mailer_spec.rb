require "rails_helper"

RSpec.describe AppointmentConfirmationMailer, type: :mailer do
  include ActiveJob::TestHelper
  include BookingSetup

  self.use_transactional_tests = false

  before do
    clear_enqueued_jobs
    clear_performed_jobs
    setup_booking
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
    Appointment.where(service_offering_id: @offering.id).delete_all
    @availability.delete
    @offering.delete
    @staff.delete
    @service.delete
    @customer.delete
    travel_back
  end

  it "queues one confirmation only after creating a reservation" do
    appointment = build_appointment

    expect { AppointmentBooking.save(appointment, {}) }
      .to have_enqueued_mail(described_class, :confirmation).once
    expect { appointment.update!(notes: "Sin perfume") }
      .not_to have_enqueued_mail(described_class, :confirmation)
  end

  it "delivers the reservation details to the customer in HTML and text" do
    appointment = build_appointment
    appointment.save!
    clear_enqueued_jobs

    email = described_class.with(appointment: appointment).confirmation

    expect(email.to).to eq([ @customer.email_address ])
    expect(email.from).to eq([ "turnos@example.com" ])
    expect(email.subject).to eq("Confirmación de tu turno")
    expect(email.html_part.body.decoded).to include("Haircut", "Laura Gomez", "08/01/2030 a las 10:00")
    expect(email.text_part.body.decoded).to include("Haircut", "Laura Gomez", "08/01/2030 a las 10:00")
  end
end
