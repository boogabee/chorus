# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
token_file = Rails.root.join('config/secret.token')
abort "No config/secret.token file found.  Run rake development:init or rake development:generate_secret_token" unless token_file.exist?

Chorus::Application.config.secret_token = token_file.read
