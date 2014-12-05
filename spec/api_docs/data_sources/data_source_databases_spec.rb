require 'spec_helper'

resource 'Greenplum/Postgres DB: data sources' do
  let(:owner) { users(:owner) }
  let(:data_source) { data_sources(:owners) }
  let!(:database) { databases(:default) }
  let!(:data_source_id) {data_source.to_param}

  before do
    log_in owner
    stub(Database).refresh.with_any_args { [database] }
  end


  get '/data_sources/:data_source_id/databases' do
    parameter :data_source_id, 'Data source id'
    pagination

    example_request 'Get a list of databases on the data source' do
      status.should == 200
    end
  end

end
