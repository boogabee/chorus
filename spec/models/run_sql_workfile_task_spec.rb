require 'spec_helper'

describe RunSqlWorkfileTask do
  # job and workfile in public workspace fixture
  let(:job) { jobs(:default) }
  let(:workfile) { workfiles(:'sql.sql') }

  describe 'assemble!' do
    let(:params) do
      {
          :action => 'run_sql_workfile',
          :workfile_id => workfile.id
      }
    end

    context 'when the workfile is in the same workspace as the job' do
      it 'creates a RunSqlWorkfileTask' do
        expect {
          JobTask.assemble!(params, job)
        }.to change(RunSqlWorkfileTask, :count).by(1)
      end

      it 'associates the task with the job' do
        expect {
          JobTask.assemble!(params, job)
        }.to change(job.job_tasks, :count).by(1)

      end

      it 'should have a reference to the workflow as payload' do
        JobTask.assemble!(params, job).reload.payload.should == workfile
      end

      context 'when the workfile is not a sql workfile' do
        let(:workfile) { FactoryGirl.create(:chorus_workfile, :file_name => 'other.not_sql', :workspace => job.workspace) }

        it 'raises' do
          expect {
            JobTask.assemble!(params, job)
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'when the workfile is not in the same workspace as the job' do
      let(:workfile) { FactoryGirl.create(:chorus_workfile, :file_name => 'other.sql') }

      it 'raises' do
        expect {
          JobTask.assemble!(params, job)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#perform' do
    let(:task) { job_tasks(:rswt) }
    let(:runner) { task.job.owner }
    let(:sql_result) { SqlResult.new }

    before do
      mock(CancelableQuery).new(is_a(DataSourceConnection), anything, runner) do
        query = Object.new
        mock(query).execute(anything, :limit => 0, :include_public_schema_in_search_path => true) {
          sql_result
        }
        query
      end
    end

    it 'executes the sql workfile' do
      task.perform
    end

    context 'when execution is successful' do
      let(:sql_result) { SqlResult.new }

      it 'returns a successful job task result' do
        result = task.perform
        result.status.should == JobTaskResult::SUCCESS
      end
    end

    context 'when execution fails' do
      let(:sql_result) { raise DataSourceConnection::QueryError.new 'query exe failure message' }

      it 'returns a failure job task result' do
        result = task.perform
        result.status.should == JobTaskResult::FAILURE
        result.message.should == 'query exe failure message'
      end
    end
  end

  describe '#derived_name' do
    let(:task) { job_tasks(:rswt) }
    it 'includes the file_name' do
      task.derived_name.should include(task.payload.file_name)
    end

    context 'when the payload has been deleted' do
      before do
        task.payload.destroy
        task.reload
      end

      it 'is [invalid]' do
        task.derived_name.should == '[invalid task]'
      end
    end
  end
end
