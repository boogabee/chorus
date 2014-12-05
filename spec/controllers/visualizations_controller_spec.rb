require 'spec_helper'

describe VisualizationsController do
  let(:user) { users(:owner) }
  let(:dataset) { datasets(:table) }
  let(:data_source_account) { dataset.schema.database.data_source.owner_account }

  before do
    log_in user
  end

  describe "#create" do
    context "succeeds" do
      it "returns json for visualization, in ascending order" do
        fake_visualization = Object.new
        mock(Visualization).build(dataset, {"type" => "frequency", "check_id" => "43"}) { fake_visualization }
        mock(fake_visualization).fetch!(data_source_account, "43")
        mock_present { |model| model.should == fake_visualization }

        post :create, :type => "frequency", :check_id => "43", :dataset_id => dataset.id
        response.status.should == 200
      end

      describe "fixtures", :greenplum_integration do
        let(:account) { GreenplumIntegration.real_account }
        before { log_in account.owner }

        generate_fixture "frequencyTask.json" do
          dataset = Dataset.find_by_name!("base_table1")

          post :create, :dataset_id => dataset.id,
              :type => "frequency",
              :check_id => "43",
              :bins => 4,
              :y_axis => "category"

          response.should be_success
        end

        generate_fixture "frequencyTaskWithErrors.json" do
          dataset = Dataset.find_by_name!("base_table1")

          post :create, :dataset_id => dataset.id,
              :type => "frequency",
              :check_id => "43",
              :bins => 4,
              :y_axis => "hippopotamus"

          response.code.should == "422"
        end

        generate_fixture "heatmapTask.json" do
          dataset = Dataset.find_by_name!("heatmap_table")

          post :create, :dataset_id => dataset.id,
              :type => "heatmap",
              :check_id => "43",
              :x_bins => 3,
              :y_bins => 3,
              :x_axis => "column1",
              :y_axis => "column2"

          response.should be_success
        end

        generate_fixture "boxplotTask.json" do
          dataset = Dataset.find_by_name!("base_table1")
           post :create, :dataset_id => dataset.id,
               :type => "boxplot",
               :check_id => "43",
               :bins => 20,
               :x_axis => "category",
               :y_axis => "column2"
        end

        generate_fixture "timeseriesTask.json" do
          dataset = Dataset.find_by_name!("base_table1")
          post :create, :dataset_id => dataset.id,
              :type => "timeseries",
              :check_id => "43",
              :time_interval => "month",
              :aggregation => "sum",
              :x_axis => "time_value",
              :y_axis => "column1"
        end

        generate_fixture "histogramTask.json" do
          dataset = Dataset.find_by_name!("base_table1")
          post :create, :dataset_id => dataset.id,
              :type => "histogram",
              :check_id => "43",
              :bins => 2,
              :x_axis => "column1"
        end
      end
    end

    context "when there is an error" do
      before do
        any_instance_of(Visualization::Histogram) do |visualization|
          stub(visualization).fetch!(data_source_account, "43") { raise PostgresLikeConnection::QueryError }
        end
      end

      it "returns an error if the query fails" do
        post :create, :type => "histogram", :check_id => '43', :dataset_id => dataset.id
        response.code.should == "422"
        decoded_errors.fields.query.INVALID.message.should_not be_nil
      end
    end

    context 'when the visualization has not been implemented' do
      before do
        any_instance_of(Visualization::SqlGenerator) do |sql_gen|
          mock(sql_gen).timeseries_row_sql.with_any_args { raise Visualization::NotImplemented }
        end
      end

      it 'returns an error' do
        post :create, :type => 'timeseries', :check_id => '43', :dataset_id => dataset.id
        response.code.should == '422'
        decoded_errors.fields.visualization.should have_key(:NOT_IMPLEMENTED)
      end
    end
  end

  describe "#destroy" do
    before do
      mock(CancelableQuery).cancel("43", user)
    end
    it "cancels the visualization query" do
      delete :destroy, :id => "43", :dataset_id => dataset.to_param
      response.should be_success
    end
  end
end
