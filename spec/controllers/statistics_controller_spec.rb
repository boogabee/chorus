require 'spec_helper'

describe StatisticsController do
  let(:user) { users(:owner) }

  before do
    log_in user
  end

  describe "#show" do
    let(:schema) { schemas(:default) }
    let(:data_source_account) { schema.database.data_source.owner_account }
    let!(:table) { datasets(:table) }

    let(:statistics) {
      DatasetStatistics.new(
          'name' => 'table',
          'description' => 'a description',
          'definition' => nil,
          'column_count' => '3',
          'row_count' => '5',
          'table_type' => 'BASE_TABLE',
          'last_analyzed' => Time.parse('2012-06-06 23:02:42.40264+00'),
          'disk_size' => '500',
          'partition_count' => '6'
      )
    }

    context "with fake gpdb" do
      def matches_model(expected_model)
        satisfy { |actual_model|
          actual_model.is_a?(expected_model.class) && actual_model.id == expected_model.id
        }
      end

      before do
        stub(DatasetStatistics).build_for(
            matches_model(table),
            matches_model(data_source_account)) {
          statistics
        }
      end

      it "should retrieve the db object for a schema" do
        get :show, :dataset_id => table.to_param

        response.code.should == "200"
        decoded_response.columns.should == 3
        decoded_response.rows.should == 5
        decoded_response.description.should == 'a description'
        decoded_response.last_analyzed_time.to_s.should == "2012-06-06T23:02:42Z"
        decoded_response.partitions.should == 6
      end

      generate_fixture "datasetStatisticsTable.json" do
        get :show, :dataset_id => table.to_param
      end

      context "generating statistics for a view" do
        let(:statistics) {
          DatasetStatistics.new(
              'description' => 'a description',
              'column_count' => '3',
              'row_count' => '0',
              'table_type' => 'VIEW',
              'last_analyzed' => nil,
              'disk_size' => '0',
              'partition_count' => '0',
              'definition' => 'Bobby DROP TABLES;'
          )
        }

        generate_fixture "datasetStatisticsView.json" do
          get :show, :dataset_id => table.to_param
        end
      end
    end

    context "with real gpdb connection", :greenplum_integration do
      let(:workspace) { workspaces(:gpdb_workspace) }
      let(:schema) { workspace.sandbox }

      context "when a chorus view uses a table that has been deleted" do
        let(:bad_chorus_view) do
          cv = FactoryGirl.build(:chorus_view, :name => "bad_chorus_view", :schema => schema, :query => "select * from bogus_table", :workspace => workspace)
          cv.save(:validate => false)
          cv
        end
        let(:user) { users(:admin) }

        it "returns a 422" do
          get :show, :dataset_id => bad_chorus_view.to_param
          response.code.should == "422"
        end
      end

      context "when the user has invalid credentials" do
        let(:dataset) { schema.datasets.first }
        let(:account) { GreenplumIntegration.real_account }
        let(:user) { account.owner }

        generate_fixture "invalidCredentialsError.json" do
          account.invalid_credentials!
          get :show, :dataset_id => dataset.to_param
        end
      end
    end

    context 'when the dataset is a HdfsDataset' do
      let!(:dataset) { datasets(:hadoop) }
      let(:data_source_account) { nil }

      it "should retrieve the db object for a schema" do
        get :show, :dataset_id => dataset.to_param

        response.code.should == "200"
        decoded_response.file_mask.should == dataset.file_mask
      end

      generate_fixture "hdfsDatasetStatistics.json" do
        get :show, :dataset_id => dataset.to_param
      end
    end
  end
end
