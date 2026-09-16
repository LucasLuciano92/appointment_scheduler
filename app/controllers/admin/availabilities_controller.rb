module Admin
  class AvailabilitiesController < BaseController
    before_action :set_availability, only: %i[show edit update destroy]
    before_action :load_choices, only: %i[new edit create update]

    def index
      @availabilities = paginate(Availability.includes(:staff_member).order(:staff_member_id, :day_of_week, :start_time))
    end

    def show
    end

    def new
      @availability = Availability.new
    end

    def create
      @availability = Availability.new(availability_params)
      if @availability.save
        redirect_to admin_availability_path(@availability), notice: "Registro creado.", status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @availability.update(availability_params)
        redirect_to admin_availability_path(@availability), notice: "Cambios guardados.", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @availability.destroy
        redirect_to admin_availabilities_path, notice: "Registro eliminado.", status: :see_other
      else
        flash.now[:alert] = "No se pudo eliminar el registro. Podés desactivarlo desde Editar."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_availability
      @availability = Availability.includes(:staff_member).find(params[:id])
    end

    def load_choices
      @staff_members = StaffMember.order(:last_name, :first_name)
    end

    def availability_params
      params.expect(availability: [ :staff_member_id, :day_of_week, :start_time, :end_time, :active ])
    end
  end
end
