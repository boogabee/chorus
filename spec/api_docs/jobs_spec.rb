require 'spec_helper'

resource 'Job' do
  let(:workspace) { workspaces(:public) }
  let(:workspace_id) { workspace.id }

  before do
    log_in users(:owner)
  end

  post '/workspaces/:workspace_id/jobs' do
    parameter :interval_unit, 'Interval Unit'
    parameter :interval_value, 'Interval Value'
    parameter :name, 'Name'
    parameter :next_run, 'Next time to run'
    parameter :workspace_id, 'Workspace ID'
    required_parameters :name, :interval_value, :interval_unit, :next_run, :workspace_id


    let(:interval_value) { '1' }
    let(:interval_unit) { 'weeks' }
    let(:name) { 'TPS reports' }
    let(:next_run) { 3.days.from_now }

    example_request 'Create a Job in a workspace' do
      status.should == 201
    end
  end

  put '/workspaces/:workspace_id/jobs/:id' do
    parameter :workspace_id, 'Workspace ID'
    parameter :id, 'Job ID'

    parameter :name, 'Name'

    required_parameters :id, :workspace_id
    scope_parameters :job, [:name]

    let(:workspace_id) { workspaces(:public).id }
    let(:id) { workspaces(:public).jobs.first.id }
    let(:name) { 'Weekly TPS Reports' }
    let(:next_run) { 3.days.from_now }

    example_request 'Update a job in a workspace' do
      status.should == 200
    end
  end

  get '/workspaces/:workspace_id/jobs' do
    parameter :workspace_id, 'Workspace ID'
    required_parameters :workspace_id

    example_request 'Display all jobs for a workspace' do
      status.should == 200
    end
  end

  get '/workspaces/:workspace_id/jobs/:id' do
    parameter :workspace_id, 'Workspace ID'
    parameter :id, 'Job ID'
    required_parameters :id, :workspace_id

    let(:id) { workspaces(:public).jobs.first.id }

    example_request 'Display a given job in a workspace with tasks' do
      status.should == 200
    end
  end

  delete '/workspaces/:workspace_id/jobs/:id' do
    parameter :workspace_id, 'Workspace ID'
    parameter :id, 'Job ID'
    required_parameters :id, :workspace_id

    let(:id) { workspaces(:public).jobs.first.id }

    example_request 'Delete a given job in a workspace' do
      status.should == 200
    end
  end

  get '/jobs/:job_id/job_results/:id' do
    parameter :job_id, 'Job ID'
    parameter :id, 'Job Result ID'
    required_parameters :id, :job_id

    let(:id) { 'latest' }
    let(:job_id) { jobs(:default).id }

    example_request 'Display the latest Job Result for a Job' do
      status.should == 200
    end
  end

  post '/jobs/:id/run' do
    parameter :id, 'Job ID'
    required_parameters :id

    let(:id) { workspaces(:public).jobs.first.id }

    example_request 'Run a job' do
      status.should == 202
    end
  end

  post '/jobs/:id/stop' do
    parameter :id, 'Job ID'
    required_parameters :id

    let(:id) { workspaces(:public).jobs.first.id }

    example_request 'Stop a job' do
      status.should == 202
    end
  end
end
