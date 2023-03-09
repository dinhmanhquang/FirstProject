# config/initializers/cors.rb

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, expose: ['X-Authentication-Token'],
                  methods: %w[get post put patch delete options head]
  end
end
