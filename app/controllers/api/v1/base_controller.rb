module Api
  module V1
    class BaseController < ActionController::API
      class InvalidPagination < StandardError; end

      PAGE_SIZE = 25
      MAX_PAGE = 1_000_000
      RATE_LIMIT_STORE = Rails.env.test? ? ActiveSupport::Cache::MemoryStore.new : Rails.cache

      before_action :prevent_caching
      around_action :use_spanish

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActionController::ParameterMissing, with: :render_bad_request
      rescue_from InvalidPagination, with: :render_invalid_pagination

      private

      attr_reader :current_api_session, :current_customer

      def authenticate_customer!
        token = request.authorization.to_s[/\ABearer ([^\s]+)\z/i, 1]
        @current_api_session = ApiSession.authenticate(token)
        @current_customer = current_api_session&.user if current_api_session&.usable?
        return if current_customer

        current_api_session&.destroy
        render_error(:unauthorized, "Se requiere un token de cliente válido.", :unauthorized)
      end

      def render_validation_errors(record)
        render json: {
          error: {
            code: "validation_failed",
            message: "No se pudo guardar el recurso.",
            details: record.errors.to_hash
          }
        }, status: :unprocessable_content
      end

      def render_error(code, message, status, details: nil)
        body = { code: code.to_s, message: message }
        body[:details] = details if details
        render json: { error: body }, status: status
      end

      def user_json(user)
        {
          id: user.id,
          first_name: user.first_name,
          last_name: user.last_name,
          email_address: user.email_address,
          phone: user.phone
        }
      end

      def service_json(service)
        {
          id: service.id,
          name: service.name,
          description: service.description,
          duration_minutes: service.duration_minutes,
          price: service.price.to_s,
          image_url: service.image.attached? ? url_for(service.image) : nil
        }
      end

      def staff_member_json(staff_member, offering: nil)
        {
          id: staff_member.id,
          first_name: staff_member.first_name,
          last_name: staff_member.last_name,
          service_offering_id: offering&.id
        }.compact
      end

      def appointment_json(appointment)
        {
          id: appointment.id,
          starts_at: appointment.starts_at.iso8601,
          ends_at: appointment.ends_at.iso8601,
          status: appointment.status,
          notes: appointment.notes,
          service: service_json(appointment.service),
          staff_member: staff_member_json(appointment.staff_member),
          created_at: appointment.created_at.iso8601,
          updated_at: appointment.updated_at.iso8601
        }
      end

      def paginate(scope)
        value = params[:page]
        raise InvalidPagination unless value.nil? || value.is_a?(String)

        page = value.nil? ? 1 : Integer(value, 10, exception: false)
        raise InvalidPagination unless (1..MAX_PAGE).cover?(page)

        records = scope.offset((page - 1) * PAGE_SIZE).limit(PAGE_SIZE + 1).to_a
        has_next_page = records.length > PAGE_SIZE
        [ records.first(PAGE_SIZE), {
          page: page,
          per_page: PAGE_SIZE,
          next_page: has_next_page ? page + 1 : nil
        } ]
      end

      def prevent_caching
        response.headers["Cache-Control"] = "no-store"
      end

      def use_spanish(&action)
        I18n.with_locale(:es, &action)
      end

      def render_not_found
        render_error(:not_found, "No se encontró el recurso solicitado.", :not_found)
      end

      def render_bad_request(error)
        render_error(:bad_request, "Faltan parámetros requeridos.", :bad_request,
          details: { parameter: error.param })
      end

      def render_invalid_pagination
        render_error(:invalid_page, "La página debe ser un número entero positivo.", :bad_request)
      end
    end
  end
end
