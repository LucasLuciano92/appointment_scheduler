class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "turnos@example.com")
  layout "mailer"
end
