Chorus::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not cache in the test environment
  config.cache_store = :null_store

  # Configure static asset server for tests with Cache-Control for performance
  config.serve_static_assets = true
  config.static_cache_control = "public, max-age=3600"

  # Log error messages when you accidentally call methods on nil
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = true

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  # Mailer config
  config.action_mailer.delivery_method = :test
  ActionMailer::Base.default from: 'Test Mailer <testmailer@example.com>', reply_to: 'Test Replyto <test_replyto@example.com>'
end
