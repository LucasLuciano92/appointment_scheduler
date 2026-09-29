class AppointmentConfirmationMailer < ApplicationMailer
  def confirmation
    @appointment = params[:appointment]
    @customer = @appointment.customer
    @service = @appointment.service
    @staff_member = @appointment.staff_member

    I18n.with_locale(:es) do
      @formatted_starts_at = I18n.l(@appointment.starts_at, format: :appointment)
      mail(to: @customer.email_address, subject: "Confirmación de tu turno")
    end
  end
end
