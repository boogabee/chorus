require 'spec_helper'
require_relative 'helpers'

describe Events::GnipStreamImportCreated do
  extend EventHelpers
  let(:workspace) { workspaces(:public) }
  let(:actor) { users(:default) }
  let(:dataset) { datasets(:table) }
  let(:gnip_data_source) { gnip_data_sources(:default) }

  subject do
    Events::GnipStreamImportCreated.add(
        :actor => actor,
        :dataset => dataset,
        :workspace => workspace,
        :destination_table => dataset.name,
        :gnip_data_source => gnip_data_source
    )
  end

  its(:dataset) { should == dataset }
  its(:targets) { should == {:workspace => workspace, :dataset => dataset, :gnip_data_source => gnip_data_source} }
  its(:additional_data) { should == {'destination_table' => dataset.name} }

  it_creates_activities_for { [gnip_data_source, workspace, dataset] }
  it_does_not_create_a_global_activity

  describe ".find_for_import" do
    let!(:import) do
      import = FactoryGirl.build(:gnip_import, :user => users(:owner),
                                 :workspace => workspaces(:public),
                                 :to_table => "new_table_for_import",
                                 :created_at => '2012-09-03 23:00:00-07',
                                 :source => gnip_data_source )
      import.save!(:validate => false)
      import
    end

    it "returns the event for the given import" do
      expected_event = described_class.last
      described_class.find_for_import(import).should == expected_event
    end
  end
end