module Admin
  class DashboardController < BaseController
    def show
      @today_count = Appointment.where(starts_at: Time.current.all_day).count
      @scheduled_count = Appointment.scheduled.where(starts_at: Time.current..).count
      @customer_count = User.customer.where(active: true).count
      @staff_count = StaffMember.where(active: true).count
      @appointments = Appointment.scheduled.includes(:customer, service_offering: [ :staff_member, :service ])
        .where(starts_at: Time.current..).order(:starts_at).limit(8)
    end
  end
end
