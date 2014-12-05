require 'spec_helper'
require_relative 'helpers'

describe Events::SchemaImportSuccess do
  extend EventHelpers

  let(:actor) { users(:owner) }
  let(:source_dataset) { datasets(:oracle_table) }
  let(:dataset) { datasets(:table) }

  subject do
    Events::SchemaImportSuccess.add(
      :actor => actor,
      :dataset => dataset,
      :source_dataset => source_dataset
    )
  end

  its(:dataset) { should == dataset }
  its(:targets) { should == {:dataset => dataset, :source_dataset => source_dataset} }

  it_creates_activities_for { [actor, dataset, source_dataset] }
  it_does_not_create_a_global_activity
end