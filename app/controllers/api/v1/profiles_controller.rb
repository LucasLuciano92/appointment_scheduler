module Api
  module V1
    class ProfilesController < BaseController
      before_action :authenticate_customer!

      def show
        render json: { data: user_json(current_customer) }
      end

      def update
        if current_customer.update(profile_params)
          render json: { data: user_json(current_customer) }
        else
          render_validation_errors(current_customer)
        end
      end

      private

      def profile_params
        params.expect(user: [ :first_name, :last_name, :email_address, :phone, :password,
          :password_confirmation ])
      end
    end
  end
end
