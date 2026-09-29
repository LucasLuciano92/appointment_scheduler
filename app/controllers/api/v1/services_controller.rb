module Api
  module V1
    class ServicesController < BaseController
      def index
        services = Service.where(active: true).with_attached_image.order(:name, :id)
        render json: { data: services.map { |service| service_json(service) } }
      end

      def show
        service = Service.where(active: true).find(params[:id])
        render json: { data: service_json(service) }
      end
    end
  end
end
