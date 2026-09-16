# Rails 8.1 starts SQLite write transactions with BEGIN IMMEDIATE. Validation
# and persistence must remain inside this transaction to serialize bookings.
class AppointmentBooking
  def self.save(appointment, attributes)
    Appointment.uncached do
      Appointment.transaction do
        appointment.lock! if appointment.persisted?
        appointment.assign_attributes(attributes)
        appointment.save
      end
    end
  rescue ActiveRecord::StatementInvalid => error
    raise unless error.cause.is_a?(SQLite3::BusyException)

    appointment.errors.add(:base, :booking_busy)
    false
  end
end
