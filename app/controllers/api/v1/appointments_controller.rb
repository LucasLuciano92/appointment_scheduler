module Api
  module V1
    class AppointmentsController < BaseController
      before_action :authenticate_customer!
      before_action :set_appointment, only: %i[show cancel]

      def index
        scope = current_customer.appointments.with_booking_details.order(starts_at: :desc, id: :desc)
        if params[:status].present?
          unless params[:status].is_a?(String) && Appointment.statuses.key?(params[:status])
            return render_error(:invalid_status, "El estado indicado no es válido.", :bad_request)
          end
          scope = scope.where(status: params[:status])
        end
        render json: { data: scope.map { |appointment| appointment_json(appointment) } }
      end

      def show
        render json: { data: appointment_json(@appointment) }
      end

      def create
        appointment = current_customer.appointments.new
        if AppointmentBooking.save(appointment, appointment_params)
          render json: { data: appointment_json(appointment) }, status: :created
        else
          render_validation_errors(appointment)
        end
      end

      def cancel
        unless @appointment.scheduled? && @appointment.starts_at > Time.current
          return render_error(:not_cancellable,
            "Solo se puede cancelar un turno propio, futuro y confirmado.", :unprocessable_entity)
        end

        if AppointmentBooking.save(@appointment, status: :cancelled)
          render json: { data: appointment_json(@appointment) }
        else
          render_validation_errors(@appointment)
        end
      end

      private

      def set_appointment
        @appointment = current_customer.appointments.with_booking_details.find(params[:id])
      end

      def appointment_params
        params.expect(appointment: [ :service_offering_id, :starts_at, :notes ])
      end
    end
  end
end
