module Admin
  class ServicesController < BaseController
    before_action :set_service, only: %i[show edit update destroy]

    def index
      @services = paginate(Service.order(:name))
    end

    def show
    end

    def new
      @service = Service.new
    end

    def create
      @service = Service.new(service_params)
      if @service.save
        redirect_to admin_service_path(@service), notice: "Registro creado.", status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @service.update(service_params)
        redirect_to admin_service_path(@service), notice: "Cambios guardados.", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @service.destroy
        redirect_to admin_services_path, notice: "Registro eliminado.", status: :see_other
      else
        flash.now[:alert] = "No se pudo eliminar el registro. Podés desactivarlo desde Editar."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_service
      @service = Service.find(params[:id])
    end

    def service_params
      params.expect(service: [ :name, :description, :duration_minutes, :price, :active ])
    end
  end
end
