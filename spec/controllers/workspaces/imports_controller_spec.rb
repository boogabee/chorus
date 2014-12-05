require 'spec_helper'

describe Workspaces::ImportsController do
  describe "#create", :greenplum_integration do
    let(:account) { GreenplumIntegration.real_account }
    let(:user) { account.owner }
    let(:database) { GreenplumIntegration.real_database }
    let(:schema) { database.schemas.find_by_name('test_schema') }
    let(:src_table) { database.find_dataset_in_schema('base_table1', 'test_schema') }
    let(:archived_workspace) { workspaces(:archived) }
    let(:active_workspace) { workspaces(:public) }

    let(:attributes) {
      HashWithIndifferentAccess.new(
        :to_table => "the_new_table",
        :sample_count => "12",
        :workspace_id => active_workspace.to_param,
        :truncate => "false",
        :dataset_id => src_table.to_param
      )
    }

    before do
      log_in account.owner
      archived_workspace.sandbox = schema
      archived_workspace.save!
    end

    after do
      schema.connect_with(account).drop_table('the_new_table')
    end

    context "when importing a dataset immediately" do
      context "into a new destination dataset" do
        before do
          attributes[:new_table] = "true"
          attributes.merge! :workspace_id => active_workspace.to_param
        end

        let(:active_workspace) { FactoryGirl.create :workspace, :name => "TestImportWorkspace", :sandbox => schema, :owner => user }

        it "uses authorization" do
          mock(subject).authorize! :can_edit_sub_objects, active_workspace
          post :create, attributes
        end

        it 'has the right response code' do
          post :create, attributes
          response.code.should == "201"
        end

        it 'creates a new import' do
          expect {
            post :create, attributes
          }.to change(WorkspaceImport, :count).by(1)
          import = WorkspaceImport.last
          import.workspace.should == active_workspace
          import.to_table.should == "the_new_table"
          import.source_dataset.should == src_table
          import.truncate.should == false
          import.user_id.should == user.id
          import.sample_count.should == 12
          import.new_table.should == true
        end

        context 'when the workspace is archived' do
          it 'returns an error for archived workspaces' do
            attributes[:workspace_id] = archived_workspace.to_param
            expect {
              post :create, attributes
            }.not_to change(WorkspaceImport, :count)
            response.code.should == "422"

          end
        end

        context 'when the table already exists' do
          it 'returns an error if table already exists' do
            post :create, attributes.merge(:to_table => "master_table1")
            response.code.should == "422"

            decoded_errors.fields.base.TABLE_EXISTS.should be_present
          end
        end

        context "when there's duplicate columns (only in Chorus View)" do
          let(:src_table) { datasets(:chorus_view) }
          before do
            stub(Dataset).find(src_table.to_param) { src_table }
            mock(src_table).check_duplicate_column.with_any_args {}
          end
          it "should check for duplicate columns" do
            post :create, attributes
          end
        end
      end

      context "when importing into an existing table" do
        let(:dst_table_name) { active_workspace.sandbox.tables.first.name }

        before do
          attributes[:new_table] = "false"
          attributes[:to_table] = dst_table_name
          attributes.merge! :workspace_id => active_workspace.to_param
        end

        context "when destination dataset is consistent with source" do
          before do
            any_instance_of(GpdbDataset) do |d|
              stub(d).can_import_into(anything) { true }
            end
            any_instance_of(Import) do |d|
              stub(d).table_exists? { true }
            end
          end

          it "creates an import for the correct dataset and returns success" do
            expect {
              post :create, attributes
            }.to change(Import, :count).by(1)
            response.should be_success
            last_import = Import.last
            last_import.source_dataset.id.should == src_table.id
            last_import.new_table.should be_false
            last_import.to_table.should_not be_nil
            last_import.sample_count.should == 12
            last_import.truncate.should be_false
          end
        end

        it "throws an error if table structure is not consistent" do
          any_instance_of(GpdbDataset) do |dataset|
            stub(dataset).can_import_into(anything) { false }
          end
          any_instance_of(Import) do |import|
            stub(import).table_exists? { true }
          end

          post :create, attributes
          response.code.should == "422"
          decoded_errors.fields.base.TABLE_NOT_CONSISTENT.should be_present
        end
      end
    end

    it_behaves_like 'a protected demo mode controller', [:create] do
      let(:params) { attributes }
    end

  end

  describe "smoke test for import schedules", :greenplum_integration do
    # In the test, use gpfdist to move data between tables in the same schema and database
    let(:data_source_account) { GreenplumIntegration.real_account }
    let(:user) { data_source_account.owner }
    let(:database) { GreenplumIntegration.real_database }
    let(:schema_name) { 'test_schema' }
    let(:schema) { database.schemas.find_by_name(schema_name) }
    let(:source_table) { "candy" }
    let(:source_table_name) { "\"#{schema_name}\".\"#{source_table}\"" }
    let(:destination_table_name) { "dst_candy" }
    let(:destination_table_fullname) { "\"test_schema\".\"dst_candy\"" }
    let(:workspace) { workspaces(:public).tap { |ws| ws.owner = user; ws.members << user; ws.sandbox = schema; ws.save! } }

    let(:table_def) { '"id" numeric(4,0),
                   "name" character varying(255),
                    "id2" integer,
                    "id3" integer,
                    "date_test" date,
                    "fraction" double precision,
                    "numeric_with_scale" numeric(4,2),
                    "time_test" time without time zone,
                    "time_with_precision" time(3) without time zone,
                    "time_with_zone" time(3) with time zone,
                    "time_stamp_with_precision" timestamp(3) with time zone,
                    PRIMARY KEY("id2", "id3", "id")'.tr("\n", "").gsub(/\s+/, " ").strip }

    let(:source_dataset) { schema.datasets.find_by_name(source_table) }
    let(:import_attributes) do
      {
        :workspace => workspace,
        :to_table => destination_table_name,
        :new_table => true,
        :dataset => nil,
        :truncate => false,
        :destination_table => destination_table_name,
        :dataset_id => source_dataset.to_param,
        :workspace_id => workspace.to_param
      }
    end

    before do
      log_in user
      GreenplumIntegration.execute_sql("delete from #{source_table_name}")

      stub(GpfdistTableCopier).gpfdist_url { Socket.gethostname }
      stub(GpfdistTableCopier).grace_period_seconds { 1 }

      GreenplumIntegration.execute_sql("insert into #{source_table_name}(id, name, id2, id3) values (1, 'marsbar', 3, 5)")
      GreenplumIntegration.execute_sql("insert into #{source_table_name}(id, name, id2, id3) values (2, 'kitkat', 4, 6)")
      GreenplumIntegration.execute_sql("drop table if exists #{destination_table_fullname}")

      # synchronously run all queued import jobs
      mock(QC.default_queue).enqueue_if_not_queued("ImportExecutor.run", anything) do |method, import_id|
        ImportExecutor.run import_id
      end
    end

    after do
      GreenplumIntegration.execute_sql("drop table if exists #{destination_table_fullname}")
    end

    it "copies data" do
      post :create, import_attributes

      GreenplumIntegration.exec_sql_line_with_results("SELECT * FROM #{destination_table_fullname}").length.should == 2
    end
  end
end
