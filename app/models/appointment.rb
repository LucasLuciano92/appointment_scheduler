class Appointment < ApplicationRecord
  belongs_to :customer, class_name: "User", inverse_of: :appointments
  belongs_to :service_offering

  has_one :staff_member, through: :service_offering
  has_one :service, through: :service_offering

  enum :status, { scheduled: 0, cancelled: 1, completed: 2 }, validate: true

  before_validation :calculate_end_time
  before_destroy :prevent_destroy

  validates :starts_at, :ends_at, presence: true
  validate :ordered_times
  validate :valid_status_transition
  validate :valid_booking, if: :booking_changed?

  private

  def booking_changed?
    new_record? || will_save_change_to_customer_id? || will_save_change_to_service_offering_id? ||
      will_save_change_to_starts_at? || will_save_change_to_ends_at?
  end

  def calculate_end_time
    return unless new_record? || will_save_change_to_starts_at? || will_save_change_to_service_offering_id?

    self.ends_at = starts_at + service.duration_minutes.minutes if starts_at && service&.duration_minutes
  end

  def ordered_times
    errors.add(:ends_at, :ordered_appointment) if starts_at && ends_at && starts_at >= ends_at
  end

  def valid_status_transition
    if new_record?
      errors.add(:status, :initial_status) unless scheduled?
    elsif will_save_change_to_status?
      unless status_in_database == "scheduled" && (cancelled? || completed?)
        errors.add(:status, :invalid_transition)
      end
      if completed? && ends_at && ends_at > Time.current
        errors.add(:status, :premature_completion)
      end
    end
  end

  def valid_booking
    if persisted? && (status_in_database != "scheduled" || !scheduled?)
      errors.add(:base, :reschedule_scheduled)
    end
    errors.add(:customer, :active_customer) unless customer&.customer? && customer.active?
    unless service_offering&.active? && staff_member&.active? && service&.active?
      errors.add(:service_offering, :active_offering)
    end
    return unless starts_at && ends_at

    errors.add(:starts_at, :future_start) unless starts_at > Time.current
    if service&.duration_minutes && ends_at != starts_at + service.duration_minutes.minutes
      errors.add(:ends_at, :matching_duration)
    end
    return unless staff_member

    unless staff_member.availabilities.active.any? { |availability| availability.covers?(starts_at, ends_at) }
      errors.add(:base, :within_availability)
    end
    conflicts = staff_member.appointments.scheduled.where.not(id: id)
      .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
    errors.add(:base, :overlapping_appointment) if scheduled? && conflicts.exists?
  end

  def prevent_destroy
    errors.add(:base, :preserve_appointment)
    throw :abort
  end
end
