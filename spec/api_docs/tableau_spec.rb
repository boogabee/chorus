require 'spec_helper'

resource "Tableau" do
  let(:dataset) { datasets(:chorus_view) }
  let(:workspace) { workspaces(:public) }
  let(:user) { dataset.data_source.owner }

  before do
    log_in user
    any_instance_of(TableauWorkbook) do |wb|
      stub(wb).save { true }
    end
  end

  post "/workspaces/:workspace_id/datasets/:dataset_id/tableau_workbooks" do
    parameter :name, "Name of the workbook to be created"
    parameter :dataset_id, "Id of the dataset to link to the workbook"
    parameter :workspace_id, "Id of the workspace containing the dataset"
    parameter :tableau_username, "Username to connect to the Tableau server"
    parameter :tableau_password, "Password to connect to the Tableau server"

    required_parameters :name
    required_parameters :dataset_id
    required_parameters :workspace_id
    required_parameters :tableau_username
    required_parameters :tableau_password

    let(:dataset_id) { dataset.id }
    let(:workspace_id) { workspace.id }
    let(:name) { 'MyTableauWorkbook'}
    let(:tableau_username) { "username" }
    let(:tableau_password) { "password" }

    example_request "Create a tableau workbook" do
      status.should == 201
    end
  end
end