class AvailableSlotFinder
  class InvalidDate < StandardError; end

  def initialize(service_offering, date)
    @service_offering = service_offering
    @date = parse_date(date)
  end

  def call
    duration = service_offering.service.duration_minutes.minutes
    appointments = scheduled_appointments

    availabilities.flat_map do |availability|
      opening = local_time(availability.start_time)
      closing = local_time(availability.end_time)
      slots = []
      starts_at = opening
      while starts_at + duration <= closing
        ends_at = starts_at + duration
        if starts_at > Time.current && appointments.none? { |item| item.starts_at < ends_at && item.ends_at > starts_at }
          slots << { starts_at: starts_at.iso8601, ends_at: ends_at.iso8601 }
        end
        starts_at += duration
      end
      slots
    end
  end

  private

  attr_reader :service_offering, :date

  def parse_date(value)
    raise InvalidDate unless value.is_a?(String) && value.match?(/\A\d{4}-\d{2}-\d{2}\z/)

    Date.iso8601(value)
  rescue Date::Error
    raise InvalidDate
  end

  def availabilities
    service_offering.staff_member.availabilities.active
      .where(day_of_week: date.wday).order(:start_time, :id)
  end

  def scheduled_appointments
    service_offering.staff_member.appointments.scheduled
      .where("starts_at < ? AND ends_at > ?", local_day.end_of_day, local_day.beginning_of_day).to_a
  end

  def local_day
    @local_day ||= date.in_time_zone
  end

  def local_time(time)
    local_day + time.seconds_since_midnight.seconds
  end
end
