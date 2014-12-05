require 'spec_helper'

resource 'JobTask' do
  before do
    log_in users(:owner)
  end

  post "/workspaces/:workspace_id/jobs/:job_id/job_tasks" do
    parameter :job_id, "Job ID"
    parameter :workspace_id, "Workspace ID"
    parameter :action, "Task Type"
    parameter :source_id, "Source Table ID"
    parameter :destination_name, "Destination Table Name"
    parameter :truncate, "Truncate destination table?"
    parameter :row_limit, "Row limit"

    let(:workspace_id) { jobs(:default).workspace.id }
    let(:job_id) { jobs(:default).id }
    let(:action) { 'import_source_data' }
    let(:source_id) { datasets(:table).id }
    let(:destination_name) { 'create_me' }
    let(:truncate) { 'false' }
    let(:row_limit) { '1000' }

    required_parameters :action, :job_id, :workspace_id

    example_request "Create a Job Task in a job in a workspace" do
      status.should == 201
    end
  end

  delete "/workspaces/:workspace_id/jobs/:job_id/job_tasks/:id" do
    parameter :name, "Name"
    parameter :job_id, "Job ID"
    parameter :id, "Job Task ID"

    let(:workspace_id) { jobs(:default).workspace.id }
    let(:job_id) { jobs(:default).id }
    let(:id) { jobs(:default).job_tasks.first.id }

    example_request "Delete a Job Task in a job in a workspace" do
      status.should == 200
    end
  end

  put "/workspaces/:workspace_id/jobs/:job_id/job_tasks/:id" do
    parameter :job_id, "Job ID"
    parameter :workspace_id, "Workspace ID"
    parameter :id, "Task ID"
    required_parameters :id, :job_id, :workspace_id

    let(:workspace_id) { jobs(:default).workspace.id }
    let(:job_id) { jobs(:default).id }
    let(:id) { jobs(:default).job_tasks.first.id }

    example_request "Update an existing task in a workspace" do
      status.should == 200
    end
  end

  put "/job_tasks/:id" do
    parameter :id, "Task ID"
    required_parameters :id

    let(:id) { jobs(:default).job_tasks.first.id }

    example_request "Update an existing task" do
      status.should == 200
    end
  end
end
