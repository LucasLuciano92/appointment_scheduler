namespace :demo do
  desc "Prepare idempotent catalog, availability, customer and admin data for the TP2 demo"
  task setup: :environment do
    admin_password = ENV.fetch("DEMO_ADMIN_PASSWORD")
    customer_password = ENV.fetch("DEMO_CUSTOMER_PASSWORD")
    result = DemoDataSetup.call(admin_password:, customer_password:)

    puts "Datos demo preparados."
    puts "Admin: #{result.admin.email_address}"
    puts "Cliente: #{result.customer.email_address}"
    puts "Servicio: #{result.service.name}"
  rescue KeyError => error
    abort "Falta la variable requerida: #{error.key}"
  rescue DemoDataSetup::ProductionEnvironmentError => error
    abort error.message
  rescue ActiveRecord::RecordInvalid => error
    abort "No se pudieron preparar los datos demo: #{error.record.errors.full_messages.join(', ')}"
  end
end
