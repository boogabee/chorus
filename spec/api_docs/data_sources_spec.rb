require 'spec_helper'

resource 'Data sources' do
  let(:owner) { users(:owner) }
  let(:owned_data_source) { data_sources(:owners) }

  before do
    log_in owner
    any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? {true} }
  end

  post '/data_sources' do
    parameter :name, 'Name to show Chorus users for data source'
    parameter :description, 'Description of data source'
    parameter :host, 'Host IP or address of data source'
    parameter :port, 'Port of data source'
    parameter :db_name, "Database on data source to use for initial connection (usually 'postgres')"
    parameter :db_username, 'Username for connection to data source'
    parameter :db_password, 'Password for connection to data source'
    parameter :shared, 'true to allow anyone to connect using these credentials, false to require individuals to enter their own credentials'
    parameter :entity_type, "The type of data source ('gpdb_data_source', 'oracle_data_source', or 'jdbc_data_source')"

    let(:name) { 'Sesame_Street' }
    let(:description) { 'Can you tell me how to get...' }
    let(:host) { 'sesame.street.local' }
    let(:port) { '5432' }
    let(:db_name) { 'postgres' }
    let(:db_username) { 'big' }
    let(:db_password) { 'bird_yellow' }
    let(:shared) { true }
    let(:entity_type) { 'gpdb_data_source' }

    required_parameters :name, :host, :db_username, :db_password, :entity_type

    example_request 'Register a data source' do
      status.should == 201
    end
  end

  get "/data_sources" do
    parameter :entity_type, "The specific type of data sources to return. Returns all types if blank"
    parameter :all, "true to return all data sources, rather than the default which only includes data sources the user has access to"
    pagination

    let(:entity_type) { "gpdb_data_source" }
    let(:accessible) { true }

    example_request "Get a list of registered data sources" do
      status.should == 200
    end
  end

  get "/data_sources/:id" do
    parameter :id, "Data sources id"
    let(:id) { owned_data_source.to_param }

    example_request "Get a registered data source" do
      status.should == 200
    end
  end

  put "/data_sources/:id" do
    parameter :id, "Data source id"
    parameter :name, "Name to show Chorus users for data source"
    parameter :description, "Description of data source"
    parameter :host, "Host IP or address of data source"
    parameter :port, "Port of data source"
    parameter :db_name, "Database on data source to use for initial connection (usually 'postgres')"

    let(:id) { owned_data_source.to_param }
    let(:name) { "Sesame_Street" }
    let(:description) { "Can you tell me how to get..." }
    let(:host) { "sesame.street.local" }
    let(:port) { "5432" }
    let(:db_name) { "postgres" }

    example_request "Update data source details" do
      status.should == 200
    end
  end

  delete "/data_sources/:id" do
    parameter :id, "Data source id"

    let(:id) { owned_data_source.to_param }
    before do
      any_instance_of(GreenplumConnection) do |connection|
        stub(connection).running?
      end
    end

    example_request "Delete a data source" do
      status.should == 200
    end
  end

  get "/data_sources/:data_source_id/workspace_detail" do
    parameter :data_source_id, "Data source id"

    let(:data_source_id) { owned_data_source.to_param }

    example_request "Get details for workspaces with sandboxes on this data source" do
      status.should == 200
    end
  end

  get "/data_sources/:data_source_id/schemas" do

    parameter :data_source_id, "Data source id"

    let(:owner) { data_source.owner }
    let(:data_source) { data_sources(:oracle) }
    let(:data_source_id) { data_sources(:oracle).to_param }
    let(:schema_1) { FactoryGirl.create(:oracle_schema) }
    let(:schema_2) { FactoryGirl.create(:oracle_schema) }

    before do
      mock(Schema).visible_to(anything, data_source) {[schema_1, schema_2]}
    end

    example_request "Get a list schemas belonging to a data source" do
      status.should == 200
    end
  end
end
