require 'spec_helper'

describe SandboxesController do
  ignore_authorization!

  let(:owner) { users(:owner) }
  let(:sandbox) { schemas(:default) }
  let(:database) { sandbox.database }
  let(:data_source) { database.data_source }
  let(:workspace) { workspaces(:no_sandbox) }
  before do
    log_in owner
  end

  describe '#create' do
    it 'uses authentication' do
      mock(subject).authorize!(:update, workspace)
      post :create, :workspace_id => workspace.id, :schema_id => sandbox.id
    end

    context 'when sandbox is an existing schema' do
      it 'sets the sandbox on the workspace' do
        expect_to_add_event(Events::WorkspaceAddSandbox, owner) do
          post :create, :workspace_id => workspace.id, :schema_id => sandbox.id
        end

        response.code.should == '201'
        workspace.reload.sandbox_id.should == sandbox.id
        workspace.has_added_sandbox.should == true
      end

      context 'when the schema is postgres' do
        let(:sandbox) { schemas(:pg) }

        it 'sets the sandbox on the workspace' do
          expect_to_add_event(Events::WorkspaceAddSandbox, owner) do
            post :create, :workspace_id => workspace.id, :schema_id => sandbox.id
          end

          response.code.should == '201'
          workspace.reload.sandbox_id.should == sandbox.id
          workspace.has_added_sandbox.should == true
        end
      end

      context 'when the schema is oracle' do
        let(:sandbox) { schemas(:oracle) }

        it 'returns 422' do
          post :create, :workspace_id => workspace.id, :schema_id => sandbox.id
          response.should be_unprocessable
        end
      end

      context 'when the schema is jdbc' do
        let(:sandbox) { schemas(:jdbc) }

        it 'returns 422' do
          post :create, :workspace_id => workspace.id, :schema_id => sandbox.id
          response.should be_unprocessable
        end
      end
    end

    context 'when the client does not pass a value for show_sandbox_datasets' do
      it 'does not change the value of show_sandbox_datasets' do
        workspace.update_attributes(:show_sandbox_datasets => true)
        post :create, :workspace_id => workspace.id, :schema_id => sandbox.id
        response.code.should == '201'

        workspace.reload.show_sandbox_datasets.should be_true
      end
    end

    context 'when the user chooses not to show sandbox schemas' do

      it 'updates the show_sandbox_datasets attribute on the workspace' do
        post :create, :workspace_id => workspace.id, :schema_id => sandbox.id, :show_sandbox_datasets => false
        response.code.should == '201'

        workspace.reload.show_sandbox_datasets.should be_false
      end
    end

    context 'with a schema that does not exist' do
      it 'returns an error' do
        post :create, :workspace_id => workspace.id, :schema_id => -1

        response.code.should == '422'
        decoded_errors.fields.database.GENERIC.message.should match /Couldn't find/
      end
    end

    context 'when new sandbox is a new schema in an existing database' do
      before do
        stub(Schema).refresh(anything, anything) {}
      end

      it 'calls create_schema' do
        any_instance_of(database.class) do |db|
          stub(db).create_schema("create_new_schema", database.data_source.owner) do |name|
            database.schemas.create!({:name => name}, :without_protection => true)
          end
        end

        post :create, :workspace_id => workspace.id, :schema_name => "create_new_schema", :database_id => database.id
        response.code.should == '201'
        workspace.reload.sandbox.name.should == "create_new_schema"
      end

      it 'returns an error if creation fails' do
        any_instance_of(database.class) do |db|
          stub(db).create_schema.with_any_args {
            raise Exception.new("Schema creation failed")
          }
        end
        post :create, :workspace_id => workspace.id, :schema_name => "create_new_schema", :database_id => database.id
        response.code.should == "422"
        decoded_errors.fields.schema.GENERIC.message.should == "Schema creation failed"
      end
    end

    context 'when new sandbox is a new schema in a new database' do
      before do
        stub(Schema).refresh(anything, anything) {}
      end

      it 'calls both create_database and create_schema' do
        any_instance_of(data_source.class) do |data_source_double|
          mock(data_source_double).create_database("new_database", data_source.owner) do |name|
            data_source.databases.create!({:name => name}, :without_protection => true)
          end
        end

        any_instance_of(database.class) do |database_double|
          mock(database_double).create_schema("create_new_schema", data_source.owner) do |name|
            database = data_source.reload.databases.find_by_name("new_database")
            FactoryGirl.create :gpdb_schema, :name => name, :database => database
          end
        end

        post :create, :workspace_id => workspace.id, :schema_name => 'create_new_schema', :database_name => 'new_database', :data_source_id => data_source.to_param
        response.code.should == '201'

        workspace.reload.sandbox.name.should == 'create_new_schema'
        workspace.reload.sandbox.database.name.should == 'new_database'
      end

      it 'does not call create_schema if the schema is public' do
        any_instance_of(data_source.class) do |data_source_double|
          stub(data_source_double).create_database('new_database', data_source.owner) do |name|
            database = FactoryGirl.create :gpdb_database, :name => name, :data_source => data_source
            schema = FactoryGirl.create :gpdb_schema, :name => 'public', :database => database
            database
          end
        end
        any_instance_of(database.class) do |database_double|
          mock(database_double).create_schema.with_any_args.times(0)
        end

        post :create, :workspace_id => workspace.id, :schema_name => 'public', :database_name => 'new_database', :data_source_id => data_source.to_param
        response.should be_success
        workspace.reload.sandbox.name.should == 'public'
        workspace.reload.sandbox.database.name.should == 'new_database'
      end

      it 'returns an error if creation fails' do
        any_instance_of(data_source.class) do |data_source|
          stub(data_source).create_database.with_any_args {
            raise Exception.new("Database creation failed")
          }
        end

        post :create, :workspace_id => workspace.id, :schema_name => 'create_new_schema', :database_name => 'new_database', :data_source_id => data_source.to_param

        response.code.should == '422'
        decoded_errors.fields.database.GENERIC.message.should == 'Database creation failed'
      end
    end

    context "with a real greenplum database", :greenplum_integration do
      let(:data_source) { GreenplumIntegration.real_data_source }
      let(:database_name) { "new_database" }
      let(:schema_name) { "new_schema" }

      after do
        data_source.connect_as(owner).execute("drop database if exists #{database_name}")
      end

      it "should work" do
        post :create, :workspace_id => workspace.id, :schema_name => schema_name, :database_name => database_name, :data_source_id => data_source.to_param
        response.code.should == '201'

        workspace.reload.sandbox.name.should == schema_name
        workspace.reload.sandbox.database.name.should == database_name
      end
    end

    context 'when sandboxes are limited by license' do
      before do
        stub(License.instance).limit_sandboxes? { true }
      end

      it 'is forbidden' do
        post :create, :workspace_id => workspace.id, :schema_id => sandbox.id
        response.should be_forbidden_by_license
      end
    end
  end
end

def expect_to_add_event(event_class, owner)
  expect {
    expect {
      yield
    }.to change(Events::Base, :count).by(1) # generates a single event
  }.to change(event_class.by(owner), :count).by(1)
end
