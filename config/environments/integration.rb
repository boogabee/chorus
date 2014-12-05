require_relative 'test'

Chorus::Application.configure do
  config.action_dispatch.show_exceptions = false # make sure capybara server middleware gets exceptions
  config.middleware.delete(::Rack::Sendfile)
  config.allow_concurrency = true
  config.action_controller.allow_forgery_protection = true
end
