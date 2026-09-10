module AdminHelper
  def person_name(person)
    "#{person.first_name} #{person.last_name}"
  end

  def offering_name(offering)
    "#{person_name(offering.staff_member)} · #{offering.service.name}"
  end

  def activation_badge(record)
    tag.span(record.active? ? "Activo" : "Inactivo", class: "badge #{record.active? ? 'active' : 'inactive'}")
  end

  def appointment_badge(appointment)
    tag.span(I18n.t("appointment_statuses.#{appointment.status}"), class: "badge #{appointment.status}")
  end

  def display_datetime(value)
    value.in_time_zone.strftime("%d/%m/%Y · %H:%M")
  end

  def page_path(page)
    url_for(params.permit(:status, :date, :staff_member_id).to_h.merge(page: page, only_path: true))
  end
end
