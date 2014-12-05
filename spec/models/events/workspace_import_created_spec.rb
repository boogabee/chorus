require 'spec_helper'
require_relative 'helpers'

describe Events::WorkspaceImportCreated do
  extend EventHelpers
  let(:source_dataset) { datasets(:other_table) }
  let(:workspace) { workspaces(:public) }
  let(:actor) { users(:default) }
  let(:dataset) { datasets(:table) }
  let!(:workspace_association) { workspace.source_datasets << source_dataset }
  subject do
    Events::WorkspaceImportCreated.add(
      :actor => actor,
      :dataset => dataset,
      :source_dataset => source_dataset,
      :workspace => workspace,
      :destination_table => dataset.name
    )
  end

  its(:dataset) { should == dataset }
  its(:targets) { should == {:workspace => workspace, :dataset => dataset, :source_dataset => source_dataset} }
  its(:additional_data) { should == {'destination_table' => dataset.name} }

  it_creates_activities_for { [actor, workspace, dataset, source_dataset] }
  it_does_not_create_a_global_activity

  describe ".find_for_import" do
    let!(:import) do
      import = FactoryGirl.build(:import, :user => users(:owner),
                         :workspace => workspaces(:public),
                         :to_table => "new_table_for_import",
                         :created_at => '2012-09-03 23:00:00-07',
                         :source => datasets(:table))
      import.save!(:validate => false)
      import
    end

    it "returns the event for the given import" do
      expected_event = described_class.last
      described_class.find_for_import(import).should == expected_event
    end
  end
end