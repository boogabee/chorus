require 'spec_helper'

require_relative 'helpers'

describe Events::SchemaImportFailed do
  extend EventHelpers

  let(:actor) { users(:owner) }
  let(:source_dataset) { datasets(:oracle_table) }
  let(:destination_dataset) { datasets(:table) }
  let(:schema) { schemas(:default) }

  subject do
    Events::SchemaImportFailed.add(
      :actor => actor,
      :source_dataset => source_dataset,
      :error_message => 'Flying Monkey Attack again',
      :destination_table => 'non_existent_table',
      :dataset => destination_dataset,
      :schema => schema
    )
  end

  its(:dataset) { should == destination_dataset }
  its(:targets) { should == {:source_dataset => source_dataset, :dataset => destination_dataset, :schema => schema } }
  its(:additional_data) { should == {'destination_table' => 'non_existent_table',
                                     'error_message' => 'Flying Monkey Attack again'} }

  it_creates_activities_for { [actor, destination_dataset, source_dataset] }
  it_does_not_create_a_global_activity
end