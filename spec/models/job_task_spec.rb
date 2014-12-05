require 'spec_helper'

describe JobTask do
  it { should validate_presence_of :type }
  it { should validate_presence_of :job_id }
  it { should belong_to(:job) }

  describe '#assemble!' do
    let(:workspace) { workspaces(:empty_workspace) }
    let(:user) { users(:owner) }
    let(:dataset) { datasets(:table) }
    let(:job) { jobs(:default) }

    let(:params) do
      {
        :action => 'import_source_data',
        :source_id => dataset.id,
        :destination_id => '2',
        :row_limit => '500',
        :truncate => false
      }
    end

    it 'adds the task to the job' do
      expect {
        JobTask.assemble!(params, job)
      }.to change(job.job_tasks, :count).by(1)
    end

    it 'chooses a non-conflicting index' do
      doomed_task = JobTask.assemble!(params, job)
      JobTask.assemble!(params, job)
      doomed_task.destroy
      JobTask.assemble!(params, job)
    end

    context 'with an invalid entity type' do
      let(:params) { { :action => 'missing' } }

      it 'raises an ApiValidation error' do
        expect {
          JobTask.assemble!(params, job)
        }.to raise_error(ApiValidationError)
      end
    end
  end

  describe '#perform' do
    it { should respond_to :perform }
  end

  describe 'deleting' do
    let(:workspace) { workspaces(:empty_workspace) }

    before do
      @job = FactoryGirl.create(:job, workspace: workspace)
      @task1 = FactoryGirl.create(:run_sql_workfile_task, index: 1, job: @job)
      @task2 = FactoryGirl.create(:run_sql_workfile_task, index: 2, job: @job)
      @task3 = FactoryGirl.create(:run_sql_workfile_task, index: 3, job: @job)
    end

    it 'compacts indices' do
      @task2.destroy
      @job.job_tasks.reload.map(&:index).should == [1,2]
    end
  end
end
