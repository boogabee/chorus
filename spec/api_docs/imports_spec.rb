require 'spec_helper'

resource 'Imports' do
  let(:workspace) { workspaces(:public) }
  let(:workspace_id) { workspace.to_param }
  let(:id) { workspace_id }
  let(:user) { workspace.owner }

  let(:dataset_id) { datasets(:table).id }

  before do
    log_in user
    stub(File).readlines.with_any_args { ['The river was there.'] }
    any_instance_of(Import) do |import|
      stub(import).table_does_not_exist
      stub(import).tables_have_consistent_schema
    end
  end

  post '/schemas/:schema_id/imports' do
    parameter :dataset_id, 'Id of the source dataset'
    parameter :to_table, 'Table name of the destination table'
    parameter :truncate, 'True/false: truncate into existing table (only if new_table is false)'
    parameter :new_table, 'True/false: if true, import into new table. Otherwise, import into existing table.'
    parameter :sample_count, 'Maximum number of rows to import'

    required_parameters :dataset_id, :to_table, :new_table

    let(:schema_id) { schemas(:default).to_param }
    let(:to_table) { 'fancyTable' }
    let(:truncate) { 'false' }
    let(:new_table) { 'true' }
    let(:sample_count) { '500' }

    example_request 'Import an Oracle dataset into a Greenplum/Postgres schema' do
      status.should == 201
    end
  end

  post '/workspaces/:workspace_id/imports' do
    parameter :dataset_id, 'Id of the source dataset'
    parameter :to_table, 'Table name of the destination table'
    parameter :truncate, 'True/false: truncate into existing table (only if new_table is false)'
    parameter :new_table, 'True/false: if true, import into new table. Otherwise, import into existing table.'
    parameter :sample_count, 'Maximum number of rows to import'

    required_parameters :dataset_id, :to_table, :new_table

    let(:to_table) { 'fancyTable' }
    let(:truncate) { 'false' }
    let(:new_table) { 'true' }
    let(:sample_count) { '500' }

    example_request 'Import a dataset into a workspace' do
      status.should == 201
    end
  end

  get '/workspaces/:workspace_id/datasets/:dataset_id/imports' do
    parameter :workspace_id, 'Id of the workspace that the dataset belongs to'
    parameter :dataset_id, 'Id of the dataset'

    required_parameters :dataset_id, :workspace_id

    example_request 'Get the last import for a dataset' do
      status.should == 200
    end
  end

  post '/workspaces/:workspace_id/csv' do
    parameter :workspace_id, 'ID of the workspace'
    parameter :file_name, 'Name of the csv file to be imported'
    parameter :contents, 'The csv file being imported'

    required_parameters :workspace_id, :file_name, :contents
    scope_parameters :csv, [:contents]

    let(:file_name) { 'test.csv'}
    let(:contents) { Rack::Test::UploadedFile.new(File.expand_path('spec/fixtures/test.csv', Rails.root), 'text/csv') }

    example_request 'Upload a CSV file for import' do
      status.should == 200
    end
  end

  post '/workspaces/:workspace_id/csv/:csv_id/imports' do
    parameter :workspace_id, 'Workspace Id'
    parameter :csv_id, 'CSV File Id'
    parameter :type, 'Table type ( existingTable, newTable )'
    parameter :column_names, 'List of columns names that the CSV will import into. The first column name passed will correspond to the first column of the CSV.'
    parameter :to_table, 'Target table name'
    parameter :has_header, 'Does the CSV file contain a header row? ( true, false )'

    required_parameters :workspace_id, :csv_id, :type, :to_table, :has_header
    scope_parameters :csv_import, [:type, :column_names, :to_table, :has_header]

    let(:csv_file) { csv_files(:default) }

    let(:csv_id)       { csv_file.id }
    let(:type)         { 'existingTable' }
    let(:to_table)     { 'a_fine_table' }
    let(:has_header) { 'true' }
    let(:column_names) { ["id", "boarding_area", "terminal"] }

    example_request 'Complete import of a CSV file' do
      status.should == 201
    end
  end

  put "/imports" do
    parameter :'id[]', "Ids of imports to cancel"
    parameter :success, "'true' to mark imports as succeeded, 'false' to mark them as failed"
    parameter :message, "Error message to display (only if marking them as failed)"

    required_parameters :'id[]', :success

    let(:user) { users(:admin) }
    let(:'id[]') { [imports(:one).to_param] }
    let(:success) { 'false' }
    let(:message) { 'Import cancelled.'}

    before do
      stub(ImportExecutor).cancel.with_any_args
    end

    example_request 'Mark imports as completed (admin only)', { :format => :json } do
      status.should == 200
    end
  end

  get "/datasets/:dataset_id/importability" do
    parameter :dataset_id, "ID of dataset"
    required_parameters :dataset_id
    let(:dataset_id) { datasets(:table).to_param }

    example_request 'Check importability of dataset', { :format => :json } do
      status.should == 200
    end
  end
end
