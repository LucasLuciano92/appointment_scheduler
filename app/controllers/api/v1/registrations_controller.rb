module Api
  module V1
    class RegistrationsController < BaseController
      rate_limit to: 5, within: 1.minute, only: :create,
        store: RATE_LIMIT_STORE,
        with: -> { render_error(:rate_limited, "Demasiados intentos. Volvé a intentar más tarde.", :too_many_requests) }

      def create
        customer = User.new(registration_params.merge(role: :customer, active: true))
        if customer.save
          _session, token = ApiSession.issue!(customer)
          render json: { data: user_json(customer), token: token }, status: :created
        else
          render_validation_errors(customer)
        end
      end

      private

      def registration_params
        params.expect(user: [ :first_name, :last_name, :email_address, :phone, :password,
          :password_confirmation ])
      end
    end
  end
end
