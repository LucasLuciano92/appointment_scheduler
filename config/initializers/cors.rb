configured_origins = ENV.fetch(
  "API_ALLOWED_ORIGINS",
  Rails.env.production? ? "" : "http://localhost:5173"
).split(",").map(&:strip).reject(&:blank?)

if configured_origins.any?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins(*configured_origins)
      resource "/api/v1/*",
        headers: :any,
        methods: %i[get post put patch delete options head]
    end
  end
end
