require 'spec_helper'

resource 'Milestone' do
  let(:workspace) { workspaces(:public) }
  let(:workspace_id) { workspace.id }
  let(:milestone) { milestones(:default) }

  before do
    log_in users(:owner)
  end

  get "/workspaces/:workspace_id/milestones" do
    parameter :workspace_id, "Workspace ID"
    required_parameters :workspace_id

    example_request "Display all milestones for a workspace" do
      status.should == 200
    end
  end

  post "/workspaces/:workspace_id/milestones" do
    parameter :workspace_id, "Workspace ID"
    parameter :name, "Milestone name"
    parameter :target_date, "Target date"
    required_parameters :workspace_id, :name, :target_date

    let(:name) { 'Another great milestone' }
    let(:target_date) { '2020-07-30T14:00:00-07:00' }

    example_request "Create a new milestone" do
      status.should == 201
    end
  end

  put "/workspaces/:workspace_id/milestones/:id" do
    parameter :workspace_id, "Workspace ID"
    parameter :id, "Milestone id"
    parameter :name, "Milestone name"
    parameter :target_date, "Target date"
    parameter :state, "Milestone state"
    required_parameters :workspace_id, :id

    let(:id) { milestone.id }

    example_request "Update a milestone" do
      status.should == 200
    end
  end

  delete "/workspaces/:workspace_id/milestones/:id" do
    parameter :workspace_id, "Workspace ID"
    parameter :id, "Milestone id"

    required_parameters :workspace_id, :id

    let(:id) { milestone.id }

    example_request "Delete a milestone" do
      status.should == 200
    end
  end
end