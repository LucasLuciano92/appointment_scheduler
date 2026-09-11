module Admin
  class AppointmentsController < BaseController
    before_action :set_appointment, only: %i[show edit update cancel complete]
    before_action :load_choices, only: %i[new create edit update]

    def index
      filter = AppointmentFilter.new(
        date: params[:date], status: params[:status], staff_member_id: params[:staff_member_id]
      )
      scope = filter.apply(Appointment.with_booking_details.order(:starts_at, :id))
      @staff_members = StaffMember.order(:last_name, :first_name)
      @appointments = paginate(scope)
    rescue AppointmentFilter::InvalidFilter
      redirect_to admin_appointments_path, alert: "Revisá la fecha, el estado y el profesional de los filtros."
    end

    def show
    end

    def new
      @appointment = Appointment.new
    end

    def create
      @appointment = Appointment.new
      if AppointmentBooking.save(@appointment, appointment_params)
        redirect_to admin_appointment_path(@appointment), notice: "Turno reservado.", status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if AppointmentBooking.save(@appointment, appointment_params)
        redirect_to admin_appointment_path(@appointment), notice: "Turno actualizado.", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def cancel
      change_status(:cancelled, "Turno cancelado.")
    end

    def complete
      change_status(:completed, "Turno completado.")
    end

    private

    def set_appointment
      @appointment = Appointment.find(params[:id])
    end

    def load_choices
      @customers = User.customer.where(active: true).or(User.customer.where(id: @appointment&.customer_id))
        .order(:last_name, :first_name)
      @offerings = ServiceOffering.joins(:staff_member, :service)
        .where(active: true, staff_members: { active: true }, services: { active: true })
        .or(ServiceOffering.joins(:staff_member, :service).where(id: @appointment&.service_offering_id))
        .includes(:staff_member, :service).order(:id)
    end

    def appointment_params
      params.expect(appointment: [ :customer_id, :service_offering_id, :starts_at, :notes ])
    end

    def change_status(status, message)
      if AppointmentBooking.save(@appointment, status: status)
        redirect_to admin_appointment_path(@appointment), notice: message, status: :see_other
      else
        render :show, status: :unprocessable_entity
      end
    end
  end
end
