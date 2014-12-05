require 'spec_helper'

resource "Workfiles" do
  let(:owner) { users(:owner) }
  let!(:workspace) { workspaces(:public) }
  let!(:workfile) { workfiles("sql.sql") }
  let!(:file) { test_file("workfile.sql", "text/sql") }
  let!(:workfile_id) { workfile.to_param }
  let(:result) { }
  let(:workflow) { workfiles(:alpine_flow) }


  before do
    log_in owner
    any_instance_of(CancelableQuery) do |query|
      stub(query).execute.with_any_args { result }
    end
    stub(CancelableQuery).cancel.with_any_args { true }
  end

  get "/workfiles/:id" do
    parameter :id, "Id of a workfile"

    required_parameters :id

    let(:id) { workfile.to_param }

    example_request "Get workfile details" do
      status.should == 200
    end
  end

  put "/workfiles/:id" do
    parameter :id, "Id of a workfile"
    parameter :"execution_schema[id]", "Id of the execution schema"
    parameter :file_name, "Filename"

    required_parameters :id

    let(:id) { workfile.to_param }
    let(:"execution_schema[id]") { schemas(:default).to_param }
    let(:file_name) { "newname.sql" }

    example_request "Update a workfile" do
      status.should == 200
    end
  end

  get "/workfiles/:workfile_id/download" do
    before do
      workfile_versions(:public).tap { |v| v.contents = file; v.save! }
    end

    parameter :workfile_id, "Id of a workfile to download"

    required_parameters :workfile_id

    let(:workspace_id) { workspace.to_param }

    example_request "Download the current version of the file" do
      status.should == 200
    end
  end

  post "/workfiles/:workfile_id/copy" do
    before do
      workfile_versions(:public).tap { |v| v.contents = file; v.save! }
    end

    parameter :workfile_id, "Id of a workfile to copy"
    parameter :workspace_id, "Id of workspace to copy to"
    parameter :file_name, "The name of the new copy"

    required_parameters :workfile_id

    let(:workspace_id) { workspace.to_param }
    let(:file_name) { "copy.sql" }

    example_request "Copy a workfile to a workspace" do
      status.should == 201
    end
  end

  post "/workfiles/:workfile_id/results" do
    parameter :workfile_id, "Id of workfile to add result"
    parameter :result_id, "Id of workfile result on alpine"

    required_parameters :workfile_id

    let(:result_id) { "0.1274758" }

    example_request "Add a workfile result to a workfile" do
      status.should == 201
    end
  end

  delete "/workfiles/:id" do
    let(:id) { workfile.to_param }
    parameter :id, "Id of the workfile to delete"
    required_parameters :id

    example_request "Delete a workfile" do
      status.should == 200
    end
  end

  get "/workspaces/:workspace_id/workfiles" do
    parameter :workspace_id, "Workspace Id"

    required_parameters :workspace_id

    let(:workspace_id) { workspace.to_param }
    pagination

    example_request "Get a list of workfiles in a workspace" do
      status.should == 200
    end
  end

  post "/workspaces/:workspace_id/workfiles" do
    let(:workspace_id) { workspace.to_param }
    let(:database_id) { databases(:default).id }

    parameter :entity_subtype, ""
    parameter :database_id, "GPDB Database Id"
    parameter :hdfs_data_source_id, "HDFS Data Source Id"
    parameter :workspace_id, "Workspace Id"
    parameter :description, "Workfile description"
    parameter :file_name, "Filename"

    required_parameters :file_name, :workspace_id

    let(:description) { "Get off my lawn, you darn kids!" }
    let(:file_name) { "new_file.sql" }

    example_request "Create a new workfile in a workspace" do
      status.should == 201
    end
  end

  delete '/workspaces/:workspace_id/workfiles' do
    parameter :workspace_id, 'Id of the workspace from which the workfiles will be deleted'
    parameter :'workfile_ids[]', 'Workfile Id to delete, can be specified multiple times'

    required_parameters :workspace_id, :'workfile_ids[]'

    let(:workspace_id) { workspace.to_param }
    let(:'workfile_ids[]') { workspace.workfiles.limit(2).pluck(:id) }

    example_request 'Disassociate a list of non-sandbox datasets with the workspace' do
      status.should == 200
    end
  end

  post "/workfiles/:workfile_id/executions" do
    parameter :workfile_id, "Workfile Id"
    parameter :check_id, "A client-generated identifier which can be used to cancel this execution later"
    parameter :sql, "SQL to execute"

    required_parameters :workfile_id, :check_id

    let(:check_id) { "12345" }

    let(:result) do
      GreenplumSqlResult.new.tap do |r|
        r.add_column("results_of", "your_sql")
      end
    end

    example_request "Execute a workfile" do
      status.should == 200
    end
  end

  delete "/workfiles/:workfile_id/executions/:id" do
    parameter :workfile_id, "Workfile Id"
    parameter :id, "A client-generated identifier, previously passed as 'check_id' to workfile execution method to identify a query"

    required_parameters :id, :workfile_id

    let(:id) { 0 }

    example_request "Cancel execution of a workfile" do
      status.should == 200
    end
  end

  post '/workfiles/:id/run' do
    before do
      stub(Alpine::API).run_work_flow.with_any_args { 'fakeprocessid' }
    end

    parameter :id, 'Id of a workflow'

    required_parameters :id

    let(:id) { workflow.to_param }

    example_request 'Run a workflow' do
      status.should == 202
    end
  end

  post '/workfiles/:id/stop' do
    before do
      stub(Alpine::API).stop_work_flow.with_any_args { OpenStruct.new({code: '200'}) }
    end

    parameter :id, 'Id of a workflow'

    required_parameters :id

    let(:id) { workflow.to_param }

    example_request 'Stop a running workflow' do
      status.should == 202
    end
  end
end
