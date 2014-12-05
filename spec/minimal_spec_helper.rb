ENV["RAILS_ENV"] ||= 'test'

require 'rr'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
end
