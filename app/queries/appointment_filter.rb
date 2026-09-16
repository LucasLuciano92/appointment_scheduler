# Validates optional HTTP filters before passing typed values to Active Record.
class AppointmentFilter
  class InvalidFilter < StandardError; end

  def initialize(date: nil, status: nil, staff_member_id: nil)
    @date = scalar(date)
    @status = scalar(status)
    @staff_member_id = scalar(staff_member_id)
  end

  def apply(scope)
    scope = scope.where(status: valid_status) if @status.present?
    scope = scope.where(starts_at: local_day.all_day) if @date.present?
    if @staff_member_id.present?
      scope = scope.joins(:service_offering).where(service_offerings: { staff_member_id: staff_id })
    end
    scope
  end

  private

  def scalar(value)
    raise InvalidFilter unless value.nil? || value.is_a?(String)

    value
  end

  def valid_status
    raise InvalidFilter unless Appointment.statuses.key?(@status)

    @status
  end

  def local_day
    raise InvalidFilter unless @date.match?(/\A\d{4}-\d{2}-\d{2}\z/)

    Date.iso8601(@date).in_time_zone
  rescue Date::Error
    raise InvalidFilter
  end

  def staff_id
    id = Integer(@staff_member_id, 10, exception: false)
    raise InvalidFilter unless (1..9_223_372_036_854_775_807).cover?(id)

    id
  end
end
