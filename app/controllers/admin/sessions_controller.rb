module Admin
  class SessionsController < BaseController
    skip_before_action :require_admin, only: %i[new create]
    rate_limit to: 10, within: 3.minutes, only: :create,
      with: -> { redirect_to new_admin_session_path, alert: "Demasiados intentos. Esperá unos minutos y volvé a intentar." }

    def new
      redirect_to admin_root_path if current_admin
    end

    def create
      credentials = params.expect(session: [ :email_address, :password ])
      user = User.authenticate_by(email_address: credentials[:email_address], password: credentials[:password])
      if user&.active? && user.admin?
        current_admin_session&.destroy
        reset_session
        session[:admin_session_id] = user.admin_sessions.create!(expires_at: 12.hours.from_now).id
        redirect_to admin_root_path, notice: "Sesión iniciada.", status: :see_other
      else
        flash.now[:alert] = "Email o contraseña incorrectos, o cuenta sin acceso administrativo."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      current_admin_session&.destroy
      reset_session
      redirect_to new_admin_session_path, notice: "Sesión cerrada.", status: :see_other
    end
  end
end
