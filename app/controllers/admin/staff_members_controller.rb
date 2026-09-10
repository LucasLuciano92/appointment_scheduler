module Admin
  class StaffMembersController < BaseController
    before_action :set_staff_member, only: %i[show edit update destroy]

    def index
      @staff_members = paginate(StaffMember.order(:last_name, :first_name))
    end

    def show
    end

    def new
      @staff_member = StaffMember.new
    end

    def create
      @staff_member = StaffMember.new(staff_member_params)
      if @staff_member.save
        redirect_to admin_staff_member_path(@staff_member), notice: "Registro creado.", status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @staff_member.update(staff_member_params)
        redirect_to admin_staff_member_path(@staff_member), notice: "Cambios guardados.", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @staff_member.destroy
        redirect_to admin_staff_members_path, notice: "Registro eliminado.", status: :see_other
      else
        flash.now[:alert] = "No se pudo eliminar el registro. Podés desactivarlo desde Editar."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_staff_member
      @staff_member = StaffMember.find(params[:id])
    end

    def staff_member_params
      params.expect(staff_member: [ :first_name, :last_name, :email_address, :phone, :active ])
    end
  end
end
