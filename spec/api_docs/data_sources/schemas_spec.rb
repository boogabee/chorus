require 'spec_helper'

resource "Schemas" do
  let!(:owned_data_source) { data_sources(:owners) }
  let(:owner) { owned_data_source.owner }
  let!(:database) { databases(:default) }
  let!(:owner_account) { owned_data_source.account_for_user(owner) }

  let(:db_schema) { schemas(:default)}
  let(:id) { db_schema.to_param }
  let(:schema_id) { db_schema.to_param }
  let(:table) { datasets(:table) }
  let(:view) { datasets(:view) }

  before do
    log_in owner
    stub(GpdbSchema).refresh(owner_account, database) { [db_schema] }
    any_instance_of(Schema) do |schema|
      stub(schema).refresh_datasets(owner_account, hash_including(:limit => 50)) { fake_relation([table, view]) }
      stub(schema).dataset_count(owner_account, {}) { 13 }
    end
    stub(Dataset).add_metadata!(anything, owner_account)
    any_instance_of(GpdbSchema) do |schema|
      stub(schema).verify_in_source { true }
      stub(schema).stored_functions(owner_account) {
        [ SchemaFunction.new(
          db_schema.name,
          "test_function",
          "SQL",
          "text",
          "{number, other}",
          "{int4,int4}",
          "select pg_sleep(100)",
          "does nothing. do not call."
        )]
      }
    end
  end

  get "/schemas/:id" do
    parameter :id, "Greenplum schema id"
    example_request "Get a specific schema" do
      status.should == 200
    end
  end

  get "/schemas/:schema_id/datasets" do
    parameter :schema_id, "Greenplum schema id"
    pagination

    example_request "Get the list of datasets for a specific schema" do
      status.should == 200
    end
  end

  get "/schemas/:schema_id/functions" do
    parameter :schema_id, "Greenplum schema id"
    pagination

    example_request "List the functions in a schema" do
      status.should == 200
    end
  end
end
