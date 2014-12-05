require 'spec_helper'
require_relative 'helpers'

describe Events::SchemaImportCreated do
  extend EventHelpers
  let(:actor) { users(:owner) }
  let(:destination_dataset) { datasets(:table) }
  let(:source_dataset) { datasets(:oracle_table) }
  let(:schema) { schemas(:oracle) }

  subject do
    Events::SchemaImportCreated.add(
      :actor => actor,
      :dataset => destination_dataset,
      :source_dataset => source_dataset,
      :schema => schema,
      :destination_table => 'non_existent_table'
    )
  end

  its(:dataset) { should == destination_dataset }
  its(:targets) { should == {:source_dataset => source_dataset, :dataset => destination_dataset, :schema => schema } }
  its(:source_dataset) { should == source_dataset }
  its(:additional_data) { should == {'destination_table' => 'non_existent_table'} }
  it_creates_activities_for { [actor, destination_dataset, source_dataset] }
  it_does_not_create_a_global_activity


  describe ".find_for_import" do
    let!(:import) do
      import = FactoryGirl.build(:schema_import, :user => users(:owner),
                                 :schema => schemas(:default),
                                 :to_table => "new_table_for_import",
                                 :created_at => '2012-09-03 23:00:00-07',
                                 :source => datasets(:oracle_table))
      import.save!(:validate => false)
      import
    end

    it "returns the event for the given import" do
      expected_event = described_class.last
      described_class.find_for_import(import).should == expected_event
    end
  end
end
