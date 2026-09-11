module Admin
  class BaseController < ApplicationController
    PAGE_SIZE = 25
    MAX_PAGE = 1_000_000

    layout "admin"
    before_action :require_admin
    before_action :prevent_caching
    around_action :use_spanish
    helper_method :current_admin

    private

    def current_admin_session
      @current_admin_session ||= AdminSession.includes(:user).find_by(id: session[:admin_session_id])
    end

    def current_admin
      current_admin_session&.user if current_admin_session&.usable?
    end

    def require_admin
      return if current_admin

      current_admin_session&.destroy
      reset_session
      redirect_to new_admin_session_path, alert: "Iniciá sesión con una cuenta administradora."
    end

    def prevent_caching
      response.headers["Cache-Control"] = "no-store"
    end

    def use_spanish(&action)
      I18n.with_locale(:es, &action)
    end

    def paginate(scope)
      requested_page = Integer(params[:page], 10, exception: false)
      @page = (1..MAX_PAGE).cover?(requested_page) ? requested_page : 1
      records = scope.offset((@page - 1) * PAGE_SIZE).limit(PAGE_SIZE + 1).to_a
      @has_next_page = records.length > PAGE_SIZE
      records.first(PAGE_SIZE)
    end
  end
end
