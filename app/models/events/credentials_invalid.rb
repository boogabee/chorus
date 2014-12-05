require 'events/base'

module Events
  class CredentialsInvalid < Base
    has_targets :data_source
  end
end