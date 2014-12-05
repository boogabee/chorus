require 'spec_helper'

require_relative 'helpers'

describe Events::WorkspaceImportFailed do
  extend EventHelpers

  let(:workspace) { workspaces(:public) }
  let(:actor) { workspace.owner }
  let(:destination_dataset) { datasets(:table) }
  let(:source_dataset) {datasets(:other_table)}
  let!(:workspace_association) { workspace.source_datasets << source_dataset }
  subject do
    Events::WorkspaceImportFailed.add(
      :actor => actor,
      :source_dataset => source_dataset,
      :destination_table => 'test',
      :workspace => workspace,
      :error_message => 'Flying Monkey Attack again',
      :dataset => destination_dataset
    )
  end

  its(:targets) { should == {:workspace => workspace, :source_dataset => source_dataset, :dataset => destination_dataset} }
  its(:additional_data) { should == {'destination_table' => 'test', 'error_message' => 'Flying Monkey Attack again'} }

  it 'has a workspace in the source_dataset' do
    subject.source_dataset.bound_workspaces.should include(workspace)
  end

  it_creates_activities_for { [actor, workspace, source_dataset, destination_dataset] }
  it_does_not_create_a_global_activity
end
