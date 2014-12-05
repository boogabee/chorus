require 'spec_helper'

resource "Data sources" do
  let(:owned_data_source) { data_sources(:shared)}
  let(:owner) { owned_data_source.owner }
  let(:new_owner) { users(:no_collaborators) }

  before do
    log_in owner
    any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? {true} }
  end

  put "/data_sources/:data_source_id/owner" do
    parameter :data_source_id, "Data source id"
    parameter :id, "The new owner's user id"

    required_parameters :data_source_id, :id

    let(:data_source_id) { owned_data_source.to_param }
    let(:id) { new_owner.to_param }

    example_request "Change the owner of a data source" do
      status.should == 200
    end
  end
end
