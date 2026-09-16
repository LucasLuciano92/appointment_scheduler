module Admin
  class ServiceOfferingsController < BaseController
    before_action :set_service_offering, only: %i[show edit update destroy]
    before_action :load_choices, only: %i[new edit create update]

    def index
      @service_offerings = paginate(ServiceOffering.includes(:staff_member, :service).order(:id))
    end

    def show
    end

    def new
      @service_offering = ServiceOffering.new
    end

    def create
      @service_offering = ServiceOffering.new(service_offering_params)
      if @service_offering.save
        redirect_to admin_service_offering_path(@service_offering), notice: "Registro creado.", status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @service_offering.update(service_offering_params)
        redirect_to admin_service_offering_path(@service_offering), notice: "Cambios guardados.", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @service_offering.destroy
        redirect_to admin_service_offerings_path, notice: "Registro eliminado.", status: :see_other
      else
        flash.now[:alert] = "No se pudo eliminar el registro. Podés desactivarlo desde Editar."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_service_offering
      @service_offering = ServiceOffering.includes(:staff_member, :service).find(params[:id])
    end

    def load_choices
      @staff_members = StaffMember.order(:last_name, :first_name)
      @services = Service.order(:name)
    end

    def service_offering_params
      params.expect(service_offering: [ :staff_member_id, :service_id, :active ])
    end
  end
end
