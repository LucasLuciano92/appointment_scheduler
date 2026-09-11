require "rails_helper"

RSpec.describe "Admin workflows", type: :system do
  include BookingSetup

  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1280, 900 ] do |options|
      options.binary = ENV["CHROME_BIN"] if ENV["CHROME_BIN"].present?
    end
    setup_booking
    @admin = User.create!(first_name: "Admin", last_name: "Salón", email_address: "admin@example.com",
      password: "password123", role: :admin)
  end

  it "manages a service with validation and deletion confirmation" do
    sign_in
    click_link "Servicios", exact: true
    click_link "Agregar servicio"
    fill_in "Nombre", with: @service.name
    fill_in "Duración (minutos)", with: 30
    fill_in "Precio (ARS)", with: 100
    click_button "Guardar"
    expect(page).to have_css(".errors", text: "ya está en uso")

    fill_in "Nombre", with: "Color completo"
    click_button "Guardar"
    expect(page).to have_text("Registro creado.")
    expect(page).to have_css("dd", text: "Color completo")

    click_link "Editar", exact: true
    uncheck "Activo"
    click_button "Guardar"
    expect(page).to have_css(".badge", text: "Inactivo")

    dismiss_confirm do
      click_button "Eliminar servicio"
    end
    expect(page).to have_css("h1", text: "Detalle de servicio")
    accept_confirm do
      click_button "Eliminar servicio"
    end
    expect(page).to have_text("Registro eliminado.")
    expect(page).not_to have_text("Color completo")
  end

  it "books and cancels a turn using the browser" do
    sign_in
    click_link "Reservar turno"
    select "Ana Perez · ana@example.com", from: "Cliente"
    select "Laura Gomez · Haircut", from: "Profesional y servicio"
    fill_in "Fecha y hora de inicio", with: @starts_at
    click_button "Guardar turno"
    expect(page).to have_text("Turno reservado.")
    expect(page).to have_css(".badge", text: "Confirmado")

    accept_confirm do
      click_button "Cancelar turno"
    end
    expect(page).to have_text("Turno cancelado.")
    expect(page).to have_css(".badge", text: "Cancelado")
    expect(page).not_to have_button("Cancelar turno")
  end

  it "keeps mobile navigation and logout usable" do
    page.current_window.resize_to(390, 844)
    sign_in
    click_link "Servicios", exact: true
    expect(page).to have_css("h1", text: "Servicios")
    expect(page).to have_css("nav a[aria-current=page]", text: "Servicios")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    click_button "Cerrar sesión"
    expect(page).to have_text("Sesión cerrada.")
    visit admin_services_path
    expect(page).to have_css("h1", text: "Todo listo para un nuevo día.")
  end

  def sign_in
    visit new_admin_session_path
    fill_in "Email", with: @admin.email_address
    fill_in "Contraseña", with: "password123"
    click_button "Ingresar"
    expect(page).to have_css("h1", text: "Resumen de la agenda")
  end
end
