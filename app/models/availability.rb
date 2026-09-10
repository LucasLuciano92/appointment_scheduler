class Availability < ApplicationRecord
  belongs_to :staff_member

  # Weekly opening hours are local wall-clock times, not UTC instants.
  self.skip_time_zone_conversion_for_attributes = [ :start_time, :end_time ]

  enum :day_of_week, {
    sunday: 0, monday: 1, tuesday: 2, wednesday: 3,
    thursday: 4, friday: 5, saturday: 6
  }, validate: true

  scope :active, -> { where(active: true) }

  validates :start_time, :end_time, presence: true
  validates :active, inclusion: { in: [ true, false ] }
  validate :ordered_times
  validate :non_overlapping_hours

  def covers?(starts_at, ends_at)
    return false unless active? && start_time && end_time && starts_at && ends_at

    local_start = starts_at.in_time_zone
    local_end = ends_at.in_time_zone
    local_start.to_date == local_end.to_date &&
      self.class.day_of_weeks[day_of_week] == local_start.wday &&
      start_time.seconds_since_midnight <= local_start.seconds_since_midnight &&
      end_time.seconds_since_midnight >= local_end.seconds_since_midnight
  end

  private

  def ordered_times
    if start_time && end_time && start_time >= end_time
      errors.add(:end_time, :ordered_availability)
    end
  end

  def non_overlapping_hours
    return unless active? && staff_member && day_of_week && start_time && end_time

    conflicts = staff_member.availabilities.active.where(day_of_week: day_of_week).where.not(id: id)
      .where("start_time < ? AND end_time > ?", end_time, start_time)
    errors.add(:base, :overlapping_availability) if conflicts.exists?
  end
end
