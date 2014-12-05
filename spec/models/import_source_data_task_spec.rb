require 'spec_helper'

describe ImportSourceDataTask do
  let(:job) { jobs(:default) }
  let(:source_dataset) { datasets(:table) }

  describe '#truncate' do
    let(:planned_job_task) do
      {
        :action => 'import_source_data',
        :is_new_table => false,
        :index => 1000,
        :source_id => source_dataset.id,
        :destination_id => '2',
        :row_limit => '500',
        :truncate => "false"
      }
    end

    it "is coerced to a boolean" do
      task = JobTask.assemble!(planned_job_task, job)
      task.reload.payload.truncate.should == false
    end
  end

  describe '.assemble!' do
    context 'with a destination dataset' do
      let(:import_data) do
        {
          :source_id => source_dataset.id,
          :destination_id => '2',
          :row_limit => '500',
          :truncate => false
        }
      end
      let(:planned_job_task) do
        {
          :action => 'import_source_data',
          :is_new_table => false,
        }.merge!(import_data)
      end

      it "should make an associated ImportSourceDataTask" do
        expect {
          expect {
            JobTask.assemble!(planned_job_task, job)
          }.to change(ImportSourceDataTask, :count).by(1)
        }.to change(job.job_tasks.reload, :count).by(1)
      end

      it "should create an ImportTemplate as its payload" do
        task = JobTask.assemble!(planned_job_task, job)
        task.payload.source.should == source_dataset
        task.payload.destination_id.should == import_data[:destination_id].to_i
        task.payload.truncate.should == import_data[:truncate]
        task.payload.row_limit.should == import_data[:row_limit].to_i
      end
    end

    context 'with a new destination table' do
      let(:import_data) do
        {
          :source_id => source_dataset.id,
          :destination_name => 'FOO',
          :row_limit => '500',
          :truncate => false
        }
      end
      let(:planned_job_task) do
        {
          :action => 'import_source_data',
          :is_new_table => false,
        }.merge!(import_data)
      end

      it "should make an ImportSourceDataTask" do
        task = JobTask.assemble!(planned_job_task, job)
        task.payload.source_id.should == import_data[:source_id]
        task.payload.destination_name.should == import_data[:destination_name]
        task.payload.truncate.should == import_data[:truncate]
        task.payload.row_limit.should == import_data[:row_limit].to_i
        task.id.should_not be_nil
      end

      it 'cannot have the same destination_name as any existing dataset in the sandbox' do
        import_data[:destination_name] = job.workspace.sandbox.datasets.first.name
        expect {
          JobTask.assemble!(planned_job_task, job)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when the workspace does not have a sandbox' do
      before do
        mock(job.workspace).sandbox { nil }
      end

      let(:import_data) do
        {
            :source_id => source_dataset.id,
            :destination_id => '2',
            :row_limit => '500',
            :truncate => false
        }
      end
      let(:planned_job_task) do
        {
            :action => 'import_source_data',
            :is_new_table => false,
        }.merge!(import_data)
      end

      it 'does not validate' do
        expect {
          JobTask.assemble!(planned_job_task, job)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe '#perform' do
    let(:isdt) { job_tasks(:isdt) }

    before do
      any_instance_of(GreenplumConnection) { |gp| stub(gp).table_exists? { false } }
    end

    it "creates an Import Object" do
      mock(ImportExecutor).run.with_any_args
      stub(isdt.payload).set_destination_id!
      expect {
        isdt.perform
      }.to change(Import, :count).by(1)
    end

    it "Runs the import through the import executor" do
      mock(ImportExecutor).run.with_any_args
      stub(isdt).set_destination_id!
      isdt.perform
    end

    describe 'when importing into a new table' do
      before do
        any_instance_of(WorkspaceImport) do |import|
          stub(import).table_does_not_exist { true }
          stub(import).tables_have_consistent_schema { true }
        end
      end
      let(:isdt) { FactoryGirl.create(:import_source_data_task_into_new_table) }

      context 'and the import completes successfully' do
        let(:dataset) { datasets(:table) }

        it 'changes the destination id to the newly created dataset id' do
          stub(ImportExecutor).run {true}
          any_instance_of(ImportTemplate) do |payload|
            stub(payload).import_created_table { dataset }
          end

          isdt.perform
          isdt.payload.destination_name.should be_nil
          isdt.payload.destination_id.should == dataset.id
        end
      end

      context 'and the import fails' do
        it 'keeps the destination_name and does not set the destination_id' do
          stub(ImportExecutor).run { raise }
          expect {
            isdt.perform
          }.not_to change(isdt.payload, :destination_name)
        end
      end
    end

    describe 'success' do
      it 'returns a successful JobTaskResult' do
        mock(ImportExecutor).run.with_any_args
        stub(isdt).set_destination_id!
        result = isdt.perform
        result.status.should == JobTaskResult::SUCCESS
        result.name.should == isdt.derived_name
      end
    end

    describe 'failure' do
      it 'returns a failed JobTaskResult' do
        stub(ImportExecutor).run { raise StandardError.new 'some msg' }
        result = isdt.perform
        result.status.should == JobTaskResult::FAILURE
        result.name.should == isdt.derived_name
        result.message.should == 'some msg'
      end
    end

    describe 'after having been cancelled' do
      context "before an import is created" do
        before do
          stub(ImportExecutor).run.with_any_args
        end

        it "returns a failed JobTaskResult" do
          isdt.kill

          result = isdt.perform
          result.status.should == JobTaskResult::FAILURE
          result.name.should == isdt.derived_name
          result.message.should == 'Canceled by User'
        end
      end
    end
  end

  describe '#derived_name' do
    let(:task) { job_tasks(:isdt) }
    it 'includes the name of the source dataset name' do
      task.derived_name.should include(task.payload.source.name)
    end

    context 'when the payload source has been deleted' do
      before do
        task.payload.source.touch :deleted_at
        task.reload
      end

      it 'is [invalid]' do
        task.derived_name.should == '[invalid task]'
      end
    end
  end

  describe 'update_attributes' do
    context 'when changing from "new table import" to "existing table import"' do
      let(:task) { FactoryGirl.create(:import_source_data_task_into_new_table)}

      it 'should nullify the payloads destination name' do
        task.update_attributes(:destination_id => source_dataset.id)
        task.payload.destination_name.should be_nil
        task.payload.destination_id.should == source_dataset.id
      end
    end

    context 'when changing from "existing table import" to "new table import"' do
      let(:task) { job_tasks(:isdt) }

      it 'should nullify the payloads destination id' do
        task.update_attributes(:destination_name => 'Foobar')
        task.payload.destination_name.should == 'Foobar'
        task.payload.destination_id.should be_nil
      end
    end
  end

  describe 'kill' do
    let(:task) { job_tasks(:isdt) }
    let(:import) { imports(:three) }

    context "when an import is running" do
      before do
        any_instance_of(ImportTemplate) do |payload|
          stub(payload).create_import { import }
        end

        stub(ImportExecutor).run do
          Thread.current[:import_started] = true
          sleep 1000
        end
      end

      it 'cancels a current import' do
        any_instance_of(Import) { |import| mock(import).mark_as_canceled!("Canceled by User") }
        thread = Thread.new { task.perform }

        wait_until { thread[:import_started] }

        task.kill
        thread.kill
      end
    end
  end
end
