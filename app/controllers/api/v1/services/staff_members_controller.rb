module Api
  module V1
    module Services
      class StaffMembersController < BaseController
        def index
          service = Service.where(active: true).find(params[:service_id])
          offerings = service.service_offerings.where(active: true)
            .joins(:staff_member).where(staff_members: { active: true })
            .includes(:staff_member).order("staff_members.last_name", "staff_members.first_name")
          render json: {
            data: offerings.map do |offering|
              staff_member_json(offering.staff_member, offering: offering)
            end
          }
        end
      end
    end
  end
end
