module Admin
  class CustomersController < BaseController
    before_action :set_customer, only: %i[show edit update destroy]

    def index
      @customers = paginate(User.customer.order(:last_name, :first_name))
    end

    def show
    end

    def new
      @customer = User.new
    end

    def create
      @customer = User.new(customer_params)
      if @customer.save
        redirect_to admin_customer_path(@customer), notice: "Registro creado.", status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @customer.update(customer_params)
        redirect_to admin_customer_path(@customer), notice: "Cambios guardados.", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @customer.destroy
        redirect_to admin_customers_path, notice: "Registro eliminado.", status: :see_other
      else
        flash.now[:alert] = "No se pudo eliminar el registro. Podés desactivarlo desde Editar."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_customer
      @customer = User.customer.find(params[:id])
    end

    def customer_params
      attributes = params.expect(customer: [ :first_name, :last_name, :email_address, :phone, :password, :password_confirmation, :active ])
      if attributes[:password].blank?
        attributes.delete(:password)
        attributes.delete(:password_confirmation)
      end
      attributes
    end
  end
end
