require 'spec_helper'

resource "Data sources: accounts" do
  let(:owner) { users(:owner) }
  let(:non_owner) { users(:no_collaborators) }
  let(:member) { users(:the_collaborator) }

  let(:data_source) { data_sources(:owners) }
  let(:data_source_id) { data_source.to_param }

  before do
    any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? {true} }
  end

  get "/data_sources/:data_source_id/account" do
    before do
      log_in owner
    end

    parameter :data_source_id, "The id of a data source"

    example_request "Get personal credentials" do
      explanation <<-DESC
        The current user's personal credentials for connecting to this
        data source.  If the data source has shared credentials, the shared credentials
        returned.
      DESC

      status.should == 200
    end
  end

  post "/data_sources/:data_source_id/account" do
    parameter :data_source_id, "The id of a data source"
    parameter :db_username, "User name for connection"
    parameter :db_password, "Password for connection"

    let(:db_username) { "big" }
    let(:db_password) { "bird_long_password" }

    required_parameters :db_username, :db_password

    before do
      log_in non_owner
    end

    example_request "Create personal credentials" do
      status.should == 201
    end
  end

  put "/data_sources/:data_source_id/account" do
    parameter :data_source_id, "The id of a data source"
    parameter :db_username, "User name for connection"
    parameter :db_password, "Password for connection"

    let(:db_username) { "snuffle" }
    let(:db_password) { "upagus" }

    required_parameters :db_username, :db_password

    before do
      log_in member
    end

    example_request "Update personal credentials" do
      status.should == 200
    end
  end

  delete "/data_sources/:data_source_id/account" do
    before do
      log_in member
    end
    parameter :data_source_id, "The id of a data source"

    example_request "Remove personal credentials" do
      status.should == 200
    end
  end
end
