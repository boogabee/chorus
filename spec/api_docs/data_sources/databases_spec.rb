require 'spec_helper'

resource 'Greenplum/Postgres DB: databases' do
  let(:owner) { users(:owner) }
  let(:owned_data_source) { data_sources(:owners) }
  let(:database) { databases(:default) }
  let(:owner_account) { owned_data_source.owner_account }
  let(:id) { database.to_param }
  let(:database_id) { database.to_param }

  let(:db_schema_1) { schemas(:default) }
  let(:db_schema_2) { schemas(:public) }

  before do
    log_in owner
    stub(Schema).refresh(owner_account, database) { [db_schema_1, db_schema_2] }
  end

  get '/databases/:id' do
    parameter :id, 'The id of a database'

    example_request 'Get a specific database' do
      status.should == 200
    end
  end

  get '/databases/:database_id/schemas' do
    parameter :database_id, 'The id of a database'
    pagination

    example_request 'Get the list of schemas for a specific database' do
      status.should == 200
    end
  end
end
