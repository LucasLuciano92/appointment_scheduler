module Api
  module V1
    class SessionsController < BaseController
      before_action :authenticate_customer!, only: :destroy
      rate_limit to: 10, within: 3.minutes, only: :create,
        with: -> { render_error(:rate_limited, "Demasiados intentos. Volvé a intentar más tarde.", :too_many_requests) }

      def create
        credentials = params.expect(session: [ :email_address, :password ])
        user = User.authenticate_by(
          email_address: credentials[:email_address], password: credentials[:password]
        )
        unless user&.active? && user.customer?
          return render_error(:invalid_credentials,
            "Email o contraseña incorrectos, o cuenta sin acceso.", :unauthorized)
        end

        _session, token = ApiSession.issue!(user)
        render json: { data: user_json(user), token: token }, status: :created
      end

      def destroy
        current_api_session.destroy!
        head :no_content
      end
    end
  end
end
