require 'spec_helper'

resource "Data sources" do
  let(:owner) { data_source.owner }
  let(:data_source_id) { data_source.to_param }

  before do
    log_in owner
  end

  post "/data_sources/:data_source_id/sharing" do
    parameter :data_source_id, "Data source id"

    let(:data_source) { data_sources(:owners) }

    example_request "Allow individual users to share the account of the owner of a data source" do
      status.should == 201
    end
  end

  delete "/data_sources/:data_source_id/sharing" do
    parameter :data_source_id, "Data source id"

    let(:data_source) { data_sources(:shared) }

    example_request "Require individual accounts to access a data source" do
      status.should == 200
    end
  end
end
