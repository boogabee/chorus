require "spec_helper"

describe AlpineWorkfile do
  let(:workspace) { workspaces(:public) }
  let(:user) { workspace.owner }
  let(:valid_params) do
    {
        :workspace => workspace,
        :entity_subtype => "alpine",
        :file_name => "sfgj",
        :owner => user
    }
  end
  let(:params) do
    valid_params.merge(:dataset_ids => [datasets(:table).id])
  end
  let(:model) { Workfile.build_for(params).tap { |file| file.save } }

  describe 'update from params' do
    context "when uploading an AFM" do
      let(:description) { "Nice workfile, good workfile, I've always wanted a workfile like you" }
      let(:file) { test_file('workflow.afm', "text/xml") }
      let(:workfile) { Workfile.build_for(params) }
      let(:hdfs) { hdfs_data_sources(:hadoop) }
      let(:params) do
        {
            :description => description,
            :entity_subtype => 'alpine',
            :versions_attributes => [{:contents => file}],
            :hdfs_data_source_id => hdfs.id,
            :database_id => "",
            :workspace => workspace,
            :owner => user
        }
      end

      before do
        any_instance_of(Alpine::API) { |api|
          stub(api).session_id
          stub(api).create_work_flow
        }
      end

      it "resolves name conflicts" do
        workfile.update_from_params!(params)
        workfile.file_name.should eq("workflow")

        second_workfile = Workfile.build_for(params)
        second_workfile.update_from_params!(params)
        second_workfile.file_name.should eq("workflow_1")
      end

      describe "notifying alpine" do
        let(:file_contents) do
          contents = params[:versions_attributes][0][:contents].read
          params[:versions_attributes][0][:contents].rewind
          contents
        end

        it "POSTs the correct xml" do
          mock(Alpine::API).create_work_flow(model, file_contents)
          model.update_from_params!(params)
        end

        context "when alpine responds with a failure" do
          before do
            any_instance_of(Alpine::API) { |api| stub(api).create_work_flow(model, file_contents) { raise Net::ProtocolError.new } }
          end

          it "should not create the workfile" do
            expect {
              model.update_from_params!(params)
            }.to raise_error(ApiValidationError)
            Workfile.find_by_id(workfile.id).should be_nil
          end
        end
      end
    end

    context 'updating an existing workfile' do
      let(:workfile) { workfiles(:alpine_flow) }
      context 'with :execution_locations' do
        let(:gpdb) { databases(:default) }
        let(:hdfs) { hdfs_data_sources(:hadoop) }
        let(:oracle) { data_sources(:oracle) }
        let(:jdbc) { data_sources(:jdbc) }
        let(:pgdb) { databases(:pg) }
        let(:all_locations) { [gpdb, hdfs, oracle, jdbc, pgdb] }

        let(:params) do
          {:id => workfile.id}
        end

        before do
          params[:execution_locations] = all_locations.map do |source|
            {:id => source.id, :entity_type => source.entity_type_name}
          end
        end

        it 'has the execution locations specified' do
          workfile.update_from_params! params
          workfile.execution_locations.map(&:id).should =~ all_locations.map(&:id)
        end

        it 'does not find gpdb data sources disguised as oracle data sources' do
          params[:execution_locations] = [{:id => gpdb.data_source.id, :entity_type => oracle.entity_type_name}]
          expect {
            workfile.update_from_params! params
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe "validations" do
    context "with an archived workspace" do
      let(:workspace) { workspaces(:archived) }

      context "on create" do
        it "is invalid" do
          model.errors_on(:workspace).should include(:ARCHIVED)
        end
      end

      context "on update" do
        let(:model) { workfiles('alpine_flow') }

        it "is valid" do
          model.workspace = workspace
          model.workspace.should be_archived
          model.update_attributes(:file_name => 'foobar')
          model.errors_on(:workspace).should_not be_present
        end
      end
    end

    context 'file name with valid characters' do
      it 'is valid' do
        params[:file_name] = 'work_(-file).sql'
        model.should be_valid
      end
    end

    context 'file name with question mark' do
      it 'is not valid' do
        params[:file_name] = 'workfile?.sql'
        model.should have_error_on(:file_name)
      end
    end

    context 'file name with a slash' do
      it 'is not valid' do
        params[:file_name] = 'a/file.sql'
        model.should have_error_on(:file_name)
      end
    end
  end

  it "has a content_type of work_flow" do
    model.content_type.should == 'work_flow'
  end

  it "has an entity_subtype of 'alpine'" do
    model.entity_subtype.should == 'alpine'
  end

  describe 'destruction' do
    it 'notifies Alpine' do
      mock(Alpine::API).delete_work_flow(model)
      model.destroy
    end
  end

  describe "new" do
    context "when passed datasets" do
      context "in a DB" do
        let(:datasetA) { datasets(:table) }
        let(:datasetB) { datasets(:other_table) }
        let(:params) { valid_params.merge({:dataset_ids => [datasetA.id, datasetB.id]}) }

        it 'sets the execution location to the GpdbDatabase where the datasets live' do
          model.execution_locations.should =~ [datasetA.database]
        end

        it 'assigns the datasets' do
          model.datasets.should =~ [datasetA, datasetB]
        end

        context "and at least one of the datasets is a chorus view" do
          let(:datasetB) { datasets(:chorus_view) }

          it "assigns chorus_view_selected" do
            AlpineWorkfile.create(params).errors_on(:datasets).should include(:chorus_view_selected)
          end
        end
      end

      context "in a Hadoop Filesystem" do
        let(:datasetA) { datasets(:hadoop) }
        let(:datasetB) { FactoryGirl.create(:hdfs_dataset, :hdfs_data_source => datasetA.hdfs_data_source) }
        let(:params) { valid_params.merge({:dataset_ids => [datasetA.id, datasetB.id]}) }

        it 'sets the execution location to the HdfsDatSource where the datasets live' do
          model.execution_locations.should =~ [datasetA.hdfs_data_source]
        end
      end

      context 'with one from each type of supported source' do
        let(:datasetA) { datasets(:hadoop) }
        let(:datasetB) { FactoryGirl.create(:hdfs_dataset) }
        let(:datasetC) { datasets(:oracle_table) }
        let(:datasetD) { datasets(:jdbc_table) }
        let(:params) { valid_params.merge({:dataset_ids => [datasetA.id, datasetB.id, datasetC.id, datasetD.id]}) }

        it 'has multiple execution locations' do
          model.execution_locations.should =~ [datasetA.execution_location, datasetB.execution_location, datasetC.execution_location, datasetD.execution_location]
        end
      end
    end
  end

  describe '#execution_locations' do
    let(:database) { databases(:default) }
    let(:hdfs) { hdfs_data_sources(:hadoop) }
    let(:params) { valid_params }

    before do
      WorkfileExecutionLocation.create!(workfile: model, execution_location: database)
      WorkfileExecutionLocation.create!(workfile: model, execution_location: hdfs)
    end

    it 'returns an array of gpdb database and hdfs data sources' do
      model.reload.execution_locations.should =~ [database, hdfs]
    end
  end

  describe "#attempt_data_source_connection" do
    let(:database) { databases(:default) }

    before do
      set_current_user(user)
      mock(database).attempt_connection(user)
      stub(model).data_sources { [database] }
    end

    it "tries to connect using the data source" do
      model.attempt_data_source_connection
    end
  end

  describe "#latest_workfile_version" do
    it 'returns nil' do
      model.latest_workfile_version.should be_nil
    end
  end

  describe "#create_new_version" do
    let(:event_params) do
      {
          :commit_message => 'new work flow'
      }
    end

    it 'creates a workfile version upgrade event with the provided commit message' do
      expect do
        model.create_new_version(user, event_params)
      end.to change(Events::WorkFlowUpgradedVersion, :count).by(1)

      event = Events::WorkFlowUpgradedVersion.last
      event.commit_message.should == 'new work flow'
      event.workfile.should == model
      event.workspace.should == model.workspace
    end
  end

  describe '#live_dataset_ids' do
    let(:workfile) { workfiles(:multiple_dataset_workflow) }
    let(:table) { datasets(:table) }
    let(:hdfs_set) { datasets(:hadoop) }
    let(:oracle_set) { datasets(:oracle_table) }
    let(:jdbc_set) { datasets(:jdbc_table) }

    it 'presents dataset ids' do
      workfile.live_dataset_ids.should =~ [table.id, hdfs_set.id, oracle_set.id, jdbc_set.id]
    end
  end

  describe "#run_now" do
    let(:workflow) { FactoryGirl.create(:work_flow) }
    let(:process_id) { 'but_soft_what_light_from_yonder_window_breaks' }

    before do
      any_instance_of(Alpine::API) {|api| stub(api).request_run.with_any_args { process_id } }
      stub(License.instance).workflow_enabled? { true }
    end

    it "uses the api to run the work flow" do
      mock(Alpine::API).run_work_flow(workflow, user) { process_id }
      workflow.run_now(user)
    end

    context "when the Alpine API returns a process ID" do
      it "sets the status to 'running'" do
        expect {
          workflow.run_now(user)
        }.to change(workflow, :status).from('idle').to('running')
      end

      it 'saves the Alpine process ID as killable_id' do
        expect {
          workflow.run_now(user)
        }.to change(workflow, :killable_id).to(process_id)
      end
    end

    context "when the Alpine API returns an empty process ID" do
      let(:process_id) { '' }

      it "leaves the status as 'idle'" do
        expect {
          workflow.run_now(user)
        }.not_to change(workflow, :status).from('idle')
      end

      it 'does not reassign a killable_id' do
        expect {
          workflow.run_now(user)
        }.not_to change(workflow, :killable_id).from(nil)
      end
    end

    context 'when the alpine api raises' do
      before do
        any_instance_of(Alpine::API) {|api| stub(api).request_run.with_any_args { raise Alpine::API::RunError } }
      end

      it 'does not put the workflow into running state and raises the exception' do
        expect {
          expect {
            workflow.run_now(user)
          }.to raise_error(Alpine::API::RunError)
        }.not_to change(workflow, :status).from('idle')
      end
    end
  end

  describe '#stop_now' do
    let(:process_id) { 'a_most_ingenious_paradox' }
    let(:workflow) { FactoryGirl.create(:work_flow, status: 'running', killable_id: process_id) }

    it "notifies alpine" do
      success_response = OpenStruct.new({code: '200'})
      mock(Alpine::API).stop_work_flow(workflow, user) { success_response }
      workflow.stop_now(user)
    end

    context "when Alpine responds with success" do
      before do
        success_response = OpenStruct.new({code: '200'})
        mock(Alpine::API).stop_work_flow(workflow, user) { success_response }
      end

      it "sets the status to 'idle'" do
        expect {
          workflow.stop_now(user)
        }.to change(workflow, :status).from('running').to('idle')
      end
    end

    context "when Alpine responds with success" do
      before do
        success_response = OpenStruct.new({code: '200'})
        mock(Alpine::API).stop_work_flow(workflow, user) { success_response }
      end

      it "sets the status to 'idle'" do
        expect {
          workflow.stop_now(user)
        }.to change(workflow, :status).from('running').to('idle')
      end
    end
  end

  describe '#copy' do
    let(:workflow) { workfiles(:alpine_flow) }
    let(:workspace) { workspaces(:private) }
    let(:user) { users(:admin) }

    it 'copies the associated data' do
      new_workfile = workflow.copy(user, workspace)
      new_workfile.file_name.should == workflow.file_name
      new_workfile.description.should == workflow.description
      new_workfile.workspace.should == workspace
      new_workfile.owner.should == user
      new_workfile.workfile_execution_locations.length.should == workflow.workfile_execution_locations.length
    end
  end

  describe '#copy!' do
    let(:workflow) { workfiles(:alpine_flow) }
    let(:workspace) { workspaces(:private) }
    let(:user) { users(:admin) }

    it 'notifies Alpine' do
      mock(Alpine::API).copy_work_flow(workflow, numeric)
      workflow.copy!(user, workspace)
    end

    it 'does not duplicate the dataset_ids from the original workflow' do
      stub(Alpine::API).copy_work_flow(workflow, numeric) { true }
      new_workfile = workflow.copy!(user, workspace)
      new_workfile.dataset_ids.should =~ []
    end

    it 'rolls back if it cannot successfully copy in alpine' do
      stub(Alpine::API).copy_work_flow(workflow, numeric) { raise ModelNotCreated.new }
      expect {
        expect {
          workflow.copy!(user, workspace)
        }.to raise_error(ModelNotCreated)
      }.to_not change(Workfile, :count)
    end
  end
end
