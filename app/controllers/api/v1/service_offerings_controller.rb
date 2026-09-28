module Api
  module V1
    class ServiceOfferingsController < BaseController
      def available_slots
        offering = ServiceOffering.where(active: true)
          .joins(:service, :staff_member)
          .where(services: { active: true }, staff_members: { active: true })
          .includes(:service, staff_member: :availabilities).find(params[:id])
        slots = AvailableSlotFinder.new(offering, params[:date]).call
        render json: { data: slots }
      rescue AvailableSlotFinder::InvalidDate
        render_error(:invalid_date, "La fecha debe tener el formato YYYY-MM-DD.", :bad_request)
      end
    end
  end
end
