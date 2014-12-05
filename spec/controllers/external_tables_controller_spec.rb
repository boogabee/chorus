require 'spec_helper'

describe ExternalTablesController do
  let(:user) { users(:the_collaborator) }
  let(:workspace) { workspaces(:public) }

  let!(:data_source_account) { sandbox.data_source.account_for_user!(user) }
  let(:sandbox) { schemas(:default) }

  let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }
  let(:hdfs_entry) { hdfs_entries(:hdfs_file) }
  let(:hdfs_directory) { hdfs_entries(:directory) }

  before { log_in user }

  describe "#create" do
    def mock_external_table_build_success
      mock(ExternalTable).build(anything) do |e|
        e[:column_names].should == %w{field1 field2}
        e[:column_types].should == %w{text text}
        e[:connection].should be_a(GreenplumConnection)
        e[:delimiter].should == ','
        e[:name].should == 'tablefromhdfs'

        yield e if block_given?
        mock(Object.new).save { true }
      end

      # Please get rid of me
      any_instance_of(Schema) do |schema|
        stub(schema).refresh_datasets do
          workspace.sandbox.datasets.create!(:name => 'tablefromhdfs')
        end
      end
    end

    let(:parameters) do
      {
          :column_names => %w{field1 field2},
          :delimiter => ',',
          :id => hdfs_data_source.id,
          :hdfs_entry_id => hdfs_entry,
          :pathname => "foo_fighter/twisted_sisters/",
          :table_name => "tablefromhdfs",
          :types => %w{text text},
          :workspace_id => workspace.id
      }
    end

    it_behaves_like "an action that requires authentication", :post, :create, :workspace_id => '-1'

    context "when the workspace has no sandbox" do
      let(:workspace) { workspaces(:private) }

      it "fails and responds unprocessable entity" do
        post :create, parameters
        response.code.should == "422"
        JSON.parse(response.body)['errors']['fields']['external_table'].should have_key('EMPTY_SANDBOX')
      end
    end

    context "when the path type is directory" do
      before do
        parameters.merge!(:file_pattern => "*.csv", :path_type => "directory")
      end

      it "initializes and calls into ExternalTable correctly" do
        mock_external_table_build_success do |ext_table_params|
          ext_table_params[:sandbox_data_source].should == workspace.sandbox.data_source
          ext_table_params[:entry_or_dataset].should == hdfs_entry
          ext_table_params[:file_pattern].should == "*"
        end

        post :create, parameters
        response.should be_success
      end

      it 'creates an HdfsDirectoryExtTableCreated event for the directory' do
        mock_external_table_build_success

        expect {
          post :create, parameters.merge!(:hdfs_entry_id => hdfs_directory.id)
        }.to change(Events::HdfsDirectoryExtTableCreated, :count).by(1)
        e = Events::Base.last
        e.workspace.should       == workspace
        e.dataset.name.should    == 'tablefromhdfs'
        e.hdfs_entry.should      == hdfs_directory
      end
    end

    context "when the path type is pattern" do
      let(:path_type) { "pattern" }

      before do
        parameters.merge!(:file_pattern => "*.csv", :path_type => "pattern")
      end

      it "initializes and calls into ExternalTable correctly" do
        mock_external_table_build_success do |ext_table_params|
          ext_table_params[:sandbox_data_source].should == workspace.sandbox.data_source
          ext_table_params[:entry_or_dataset].should == hdfs_entry
          ext_table_params[:file_pattern].should == "*.csv"
        end

        post :create, parameters
        response.should be_success
      end

      it 'creates an HdfsPatternExtTableCreated event for the file pattern' do
        mock_external_table_build_success

        expect {
          post :create, parameters.merge(:file_pattern => '*.csv', :hdfs_entry_id => hdfs_directory.id)
        }.to change(Events::HdfsPatternExtTableCreated, :count).by(1)
        e = Events::Base.last
        e.workspace.should    == workspace
        e.dataset.name.should == 'tablefromhdfs'
        e.hdfs_entry.should   == hdfs_directory
        e.file_pattern.should == '*.csv'
      end
    end

    context "when creating from an HDFS dataset" do
      let(:hdfs_dataset) { datasets(:hadoop) }

      before do
        parameters.merge!(:hdfs_dataset_id => hdfs_dataset.id)
        parameters.delete(:hdfs_entry_id)
      end

      it "initializes and calls into ExternalTable correctly" do
        mock_external_table_build_success do |ext_table_params|
          ext_table_params[:sandbox_data_source].should == workspace.sandbox.data_source
          ext_table_params[:entry_or_dataset].should == hdfs_dataset
          ext_table_params[:file_pattern].should be_nil
        end

        post :create, parameters
      end

      it 'creates an HdfsDatasetExtTableCreated event for the dataset' do
        mock_external_table_build_success

        expect {
          post :create, parameters
        }.to change(Events::HdfsDatasetExtTableCreated, :count).by(1)
        e = Events::Base.last
        e.workspace.should    == workspace
        e.dataset.name.should == 'tablefromhdfs'
        e.hdfs_dataset.should   == hdfs_dataset
      end
    end

    describe "creating an external table form a file" do
      it "initializes and calls into ExternalTable correctly" do
        mock_external_table_build_success do |ext_table_params|
          ext_table_params[:sandbox_data_source].should == workspace.sandbox.data_source
          ext_table_params[:entry_or_dataset].should == hdfs_entry
          ext_table_params[:file_pattern].should be_nil
        end

        post :create, parameters
      end

      it "creates an HdfsFileExtTableCreated event with the hdfs file" do
        mock_external_table_build_success

        expect {
          post :create, parameters
        }.to change(Events::HdfsFileExtTableCreated, :count).by(1)

        e = Events::Base.last
        e.workspace.should == workspace
        e.dataset.name.should == 'tablefromhdfs'
        e.hdfs_entry.should == hdfs_entry
      end
    end

    it "presents any errors that come from the model" do
      mock(ExternalTable).build(anything) do
        o = ExternalTable.new
        mock(o).save { o.errors.add(:name, :TAKEN); false }
      end

      post :create, parameters
      response.code.should == "422"
      JSON.parse(response.body)['errors']['fields']['name'].should have_key('TAKEN')
    end
  end
end
