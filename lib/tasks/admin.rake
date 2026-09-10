require "io/console"

namespace :admin do
  desc "Create an administrator (interactive, or using ADMIN_* environment variables)"
  task create: :environment do
    read_value = ->(key, prompt) do
      ENV[key] || begin
        print prompt
        $stdin.gets&.strip
      end
    end

    attributes = {
      first_name: read_value.call("ADMIN_FIRST_NAME", "Nombre: "),
      last_name: read_value.call("ADMIN_LAST_NAME", "Apellido: "),
      email_address: read_value.call("ADMIN_EMAIL", "Email: "),
      password: ENV["ADMIN_PASSWORD"] || $stdin.getpass("Contraseña: "),
      role: :admin
    }
    user = User.new(attributes)
    if user.save
      puts "Cuenta administradora creada. Ingresá en /admin."
    else
      abort "No se pudo crear la cuenta: #{user.errors.full_messages.join(', ')}"
    end
  end
end
