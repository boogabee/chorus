require 'spec_helper'

describe Events::ImportCreatedBase do
  let(:source_dataset) { datasets(:other_table) }
  let(:workspace) { workspaces(:public) }
  let(:actor) { users(:default) }
  let(:dataset) { datasets(:table) }
  let(:event) do
    Events::WorkspaceImportCreated.add(
      :actor => actor,
      :source_dataset => source_dataset,
      :workspace => workspace,
      :destination_table => 'some_new_dataset'
    )
  end

  it 'adds a new activity item when its dataset is updated' do
    existing_activities = event.activities.to_a

    expect do
      event.dataset = dataset
      event.save!
    end.to change(event.activities, :count).by(1)

    (event.reload.activities - existing_activities).first.entity.should == dataset
  end
end