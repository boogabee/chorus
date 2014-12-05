require 'spec_helper'

describe JobTasksController do
  let(:workspace) { workspaces(:public) }
  let(:job) { jobs(:default) }
  let(:user) { users(:owner) }
  let(:dataset) { datasets(:table) }

  before do
    log_in user
  end

  describe '#create' do
    let(:destination_dataset) { datasets(:other_table) }
    let(:params) do
      {
        :workspace_id => workspace.id,
        :job_id => job.id,
        :job_task => planned_job_task
      }
    end
    let(:planned_job_task) { {} }

    it 'uses authorization' do
      mock(subject).authorize! :can_edit_sub_objects, workspace
      post :create, params
    end

    context 'import tasks' do
      let(:planned_job_task) do
        {
          :action => 'import_source_data',
          :source_id => dataset.id,
          :destination_id => destination_dataset.id,
          :row_limit => '500',
          :truncate => false,
          :index => 150
        }
      end

      context 'with an existing destination table' do
        it 'creates a job task' do
          expect do
            post :create, params
          end.to change(ImportSourceDataTask, :count).by(1)
        end
      end

      context 'with a new destination table' do
        let(:planned_job_task) do
          {
            :action => 'import_source_data',
            :source_id => dataset.id,
            :destination_name => 'into_this_one',
            :row_limit => '500',
            :truncate => false,
            :index => '45'
          }
        end

        it 'creates a job task' do
          expect do
            post :create, params
          end.to change(ImportSourceDataTask, :count).by(1)
        end
      end

      it 'returns 201' do
        post :create, params
        response.code.should == '201'
      end

      context 'when the workspace does not have a sandbox' do
        before do
          job.workspace.sandbox.delete
          post :create, params
        end

        it 'returns 422' do
          response.should be_unprocessable
          decoded_errors.fields.base.should have_key(:EMPTY_SANDBOX)
        end
      end
    end

    context 'run sql tasks' do
      let(:workfile) { workfiles(:'sql.sql') }
      let(:planned_job_task) do
        {
            :action => 'run_sql_workfile',
            :workfile_id => workfile.id
        }
      end

      it 'creates the task' do
        expect {
          post :create, params
        }.to change(RunSqlWorkfileTask, :count).by(1)
      end

      it 'returns 201' do
        post :create, params
        response.code.should == '201'
      end
    end
  end

  describe '#update' do
    let(:task) { job_tasks(:isdt) }
    let(:params) do
      {
        :id => task.id,
        :workspace_id => workspace.id,
        :job_id => job.id,
        :job_task => planned_job_task
      }
    end

    it 'can be called with only a task_id' do
      put :update, id: task.id, job_task: { status: 'finished' }
      task.reload.status.should == 'finished'
    end

    context 'import_source_data' do
      let(:planned_job_task) do
        {
          :action => 'import_source_data',
          :source_id => dataset.id,
          :destination_id => nil,
          :destination_name => 'sandwich_table',
          :row_limit => '500',
          :truncate => false,
          :index => 150
        }
      end

      it 'changes a job task' do
        expect do
          put :update, params
        end.to change { task.payload.reload.destination_name }.to('sandwich_table')
        decoded_response[:destination_name].should == 'sandwich_table'
        response.code.should == "200"
      end

      it "uses authorization" do
        mock(subject).authorize! :can_edit_sub_objects, workspace
        put :update, params
      end
    end

    context "run work flow" do
      let(:task) { job_tasks(:rwft) }
      let(:desired_work_flow) { FactoryGirl.create(:work_flow, :workspace => workspaces(:public), :owner => users(:owner)) }
      let(:params) do
        {
            id: task.id,
            job_id: task.job.id,
            workspace_id: task.job.workspace.id,
            job_task: {
                workfile_id: desired_work_flow.id
            },
        }
      end

      it 'updates the task' do
        expect do
          put :update, params
        end.to change { task.reload.payload.id }.to(desired_work_flow.id)
      end
    end

    context 'run sql workfile' do
      let(:task) { job_tasks(:rswt) }
      let(:desired_work_flow) { FactoryGirl.create(:chorus_workfile, :file_name => 'another.sql', :workspace => workspaces(:public), :owner => users(:owner)) }
      let(:params) do
        {
            id: task.id,
            job_id: task.job.id,
            workspace_id: task.job.workspace.id,
            job_task: {
                workfile_id: desired_work_flow.id
            },
        }
      end

      it 'updates the task' do
        expect do
          put :update, params
        end.to change { task.reload.payload.id }.to(desired_work_flow.id)
      end
    end

    describe "swapping indices" do
      let(:job)   { FactoryGirl.create(:job, workspace: workspace) }
      let!(:task1) { FactoryGirl.create(:import_source_data_task, job: job, index: 1) }
      let!(:task2) { FactoryGirl.create(:import_source_data_task, job: job, index: 2) }
      let!(:task3) { FactoryGirl.create(:import_source_data_task, job: job, index: 3) }
      let(:params) do
        {
            id: task.id,
            job_id: task.job.id,
            workspace_id: task.job.workspace.id,
            job_task: {
                index: index
            },
        }
      end

      context "when going down" do
        let(:task) { task1 }
        let(:index) { 2 }
        it "swaps with the next task" do
          put :update, params
          task1.reload.index.should == 2
          task2.reload.index.should == 1
        end
      end

      context "when going up" do
        let(:task) { task3 }
        let(:index) { 2 }
        it "swaps with the next task" do
          put :update, params
          task2.reload.index.should == 3
          task3.reload.index.should == 2
        end
      end
    end
  end

  describe "destroy" do
    let(:task) { job_tasks(:isdt) }
    let(:params) do
      {
        workspace_id: workspace.id,
        job_id: job.id,
        id: task.id
      }
    end

    it "lets a workspace member soft delete an job task" do
      delete :destroy, params
      response.should be_success
      task.reload.deleted?.should be_true
    end

    it "uses authorization" do
      mock(controller).authorize!(:can_edit_sub_objects, workspace)
      delete :destroy, params
    end
  end
end
