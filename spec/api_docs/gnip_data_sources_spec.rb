require 'spec_helper'

resource "Gnip data sources" do
  let(:user) { users(:owner) }
  let(:gnip_data_source) { gnip_data_sources(:default) }

  before do
    log_in user
    any_instance_of(ChorusGnip) do |c|
      stub(c).auth { true }
    end
  end

  post "/gnip_data_sources" do
    parameter :name, "gnip account name"
    parameter :description, "gnip account description"
    parameter :stream_url, "gnip stream url"
    parameter :username, "gnip account username"
    parameter :password, "gnip account password"

    let(:name) { "example_name" }
    let(:description) { "Can you tell me how to get..." }
    let(:stream_url) { "https://historical.gnip.com/fake" }
    let(:username) { "example_user" }
    let(:password) { "sample_password" }

    required_parameters :name, :stream_url, :username, :password

    example_request "Register a Gnip data source" do
      status.should == 201
    end
  end

  get "/gnip_data_sources" do
    pagination

    example_request "Get a list of registered Gnip data sources" do
      status.should == 200
    end
  end

  get "/gnip_data_sources/:id" do
    parameter :id, "gnip data source id"

    let(:id) { gnip_data_sources(:default).id }
    example_request "Get a registered Gnip data source" do
      status.should == 200
    end
  end

  put "/gnip_data_sources/:id" do
    parameter :id, "gnip data source id"
    parameter :name, "gnip account name"
    parameter :description, "gnip account description"
    parameter :stream_url, "gnip stream url"
    parameter :username, "gnip account username"
    parameter :password, "gnip account password (password is not updated unless this parameter is provided)"

    let(:id) { gnip_data_source.to_param }
    let(:name) { "example_name" }
    let(:description) { "Can you tell me how to get..." }
    let(:stream_url) { "https://historical.gnip.com/fake" }
    let(:username) { "example_user" }
    let(:password) { "" }

    required_parameters :name, :stream_url, :username

    example_request "Update a registered Gnip data source" do
      status.should == 200
    end
  end

  post "/gnip_data_sources/:gnip_data_source_id/imports" do
    before do
      stub(GnipImport).create!.with_any_args { imports(:gnip) }
      any_instance_of(GnipImport) { |gi| stub(gi).enqueue_import }
    end

    parameter :gnip_data_source_id, "gnip data source id"
    parameter :workspace_id, "workspace id that will receive the import"
    parameter :to_table, "new table name in the sandbox"

    required_parameters :workspace_id, :to_table

    let(:gnip_data_source_id) { gnip_data_source.to_param }
    let(:workspace_id) { workspaces(:public).id }
    let(:to_table) { "target_table" }

    example_request "Import data from Gnip" do
      status.should == 200
    end
  end

  delete "/gnip_data_sources/:id" do
    parameter :id, "gnip data source id"

    let(:id) { gnip_data_source.to_param }

    example_request "Delete a Gnip data source" do
      status.should == 200
    end
  end
end