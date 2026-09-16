module AdminHelper
  def admin_navigation_items
    {
      "Resumen" => admin_root_path,
      "Turnos" => admin_appointments_path,
      "Clientes" => admin_customers_path,
      "Personal" => admin_staff_members_path,
      "Servicios" => admin_services_path,
      "Ofertas" => admin_service_offerings_path,
      "Disponibilidad" => admin_availabilities_path
    }
  end

  def admin_navigation_link(label, path)
    selected = request.path == path || (path != admin_root_path && request.path.start_with?("#{path}/"))
    link_to label, path, class: ("selected" if selected), aria: { current: ("page" if selected) }
  end

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
