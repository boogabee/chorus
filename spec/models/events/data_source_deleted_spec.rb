require 'spec_helper'

require_relative 'helpers'

describe Events::DataSourceDeleted do
  extend EventHelpers

  let(:actor) { users(:owner) }
  let(:data_source) { data_sources(:default) }

  subject do
    Events::DataSourceDeleted.add(
        :actor => actor,
        :data_source => data_source
    )
  end

  its(:data_source) { should == data_source }
  its(:targets) { should == {:data_source => data_source} }

  it_creates_activities_for { [actor] }
  it_creates_a_global_activity
end