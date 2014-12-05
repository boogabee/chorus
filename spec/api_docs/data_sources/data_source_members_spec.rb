require 'spec_helper'

resource "Data source members" do
  let(:owner) { users(:owner) }
  let(:non_member) { users(:no_collaborators) }
  let!(:member_account) { data_source.account_for_user(member) }
  let!(:member) { users(:the_collaborator) }

  let!(:data_source) { data_sources(:owners) }
  let(:data_source_id) { data_source.to_param }

  before do
    log_in owner
    any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? {true} }
  end

  get "/data_sources/:data_source_id/members" do
    parameter :data_source_id, "Data source id"
    pagination

    example_request "List members with access to data source" do
      explanation <<-DESC
        For a Greenplum data source owner to manage which users can access their
        data sources.  When the data source is shared this list will only
        return the data source owner's credentials.  When the data source
        is not shared, this list includes people who were added by the owner
        or who have manually added their own credentials.
      DESC

      status.should == 200
    end
  end

  post "/data_sources/:data_source_id/members" do
    parameter :data_source_id, "Data source id"
    parameter :owner_id, "User ID of new member"
    parameter :db_username, "Username for account that connects to data source"
    parameter :db_password, "Password for account that connects to data source"

    let(:owner_id) { non_member.to_param }
    let(:db_username) { "big" }
    let(:db_password) { "bird_grosservogel" }

    required_parameters :owner_id, :db_username, :db_password

    example_request "Add account for a Chorus user" do
      status.should == 201
    end
  end

  put "/data_sources/:data_source_id/members/:id" do
    parameter :data_source_id, "Data source id"
    parameter :id, "Account ID of member to update"
    parameter :db_username, "Username for account that connects to data source"
    parameter :db_password, "Password for account that connects to data source"

    let(:id) { member_account.to_param }
    let(:db_username) { "snuffle" }
    let(:db_password) { "upagus" }

    required_parameters :db_username, :db_password

    example_request "Update member's account" do
      status.should == 200
    end
  end

  delete "/data_sources/:data_source_id/members/:id" do
    parameter :data_source_id, "Data source id"
    parameter :id, "Account ID of member to delete"

    let(:id) { member_account.to_param }

    example_request "Remove member's account" do
      status.should == 200
    end
  end
end
