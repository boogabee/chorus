require 'spec_helper'
require_relative 'helpers'

describe Events::CredentialsInvalid do
  extend EventHelpers
  let(:actor) { users(:owner) }
  let(:data_source) { data_sources(:default) }

  subject do
    Events::CredentialsInvalid.add(
      :actor => actor,
      :data_source => data_source
    )
  end

  its(:targets) { should == {:data_source => data_source} }

  it_does_not_create_a_global_activity
end
