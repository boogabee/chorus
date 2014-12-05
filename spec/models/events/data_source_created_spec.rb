require 'spec_helper'

require_relative 'helpers'

describe Events::DataSourceCreated do
  extend EventHelpers

  let(:actor) { users(:owner) }
  let(:data_source) { data_sources(:default) }

  subject do
    Events::DataSourceCreated.add(
        :actor => actor,
        :data_source => data_source
    )
  end

  its(:action) { should == "DataSourceCreated" }
  its(:data_source) { should == data_source }
  its(:targets) { should == {:data_source => data_source} }

  it_creates_activities_for { [actor, data_source] }
  it_creates_a_global_activity
end