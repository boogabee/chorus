require 'spec_helper'

describe HdfsDataSourcesController do
  ignore_authorization!

  let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }

  before do
    @user = users(:no_collaborators)
    log_in @user
  end

  describe "#create" do
    context "with valid attributes" do
      before do
        stub(Hdfs::DataSourceRegistrar).create!( {}, @user) { hdfs_data_source }
      end

      it "reports that the data source was created" do
        post :create
        response.code.should == "201"
      end

      it "renders the newly created data source" do
        post :create
        decoded_response.name.should == hdfs_data_source.name
      end

      it "schedules a job to refresh the data source" do
        mock(QC.default_queue).enqueue_if_not_queued("HdfsDataSource.refresh", numeric)
        post :create
      end

      describe 'restrictions' do
        before do
          stub(ChorusConfig.instance).restrict_data_source_creation? { !creatable }
        end

        context 'when data source creation is restricted' do
          let(:creatable) { false }

          it 'forbids a non-admin user' do
            post :create
            response.should be_forbidden
          end
        end

        context 'when data source creation is not restricted' do
          let(:creatable) { true }

          it 'allows a non-admin user' do
            post :create
            response.should_not be_forbidden
          end
        end
      end
    end

    context "for a high availability data source" do
      let(:params) { FactoryGirl.attributes_for(:hdfs_data_source, :high_availability => true, :connection_parameters => [{"a.key" => "a.value"}]) }

      before do
        stub(Hdfs::DataSourceRegistrar).verify_accessibility!.with_any_args { true }
        stub(Hdfs::QueryService).version_of.with_any_args { "Cloudera CDH4" }
      end

      it "renders the new data source" do
        post :create, params
        decoded_response.high_availability.should == true
        decoded_response.connection_parameters.should == [{"a.key" => "a.value"}]
      end
    end
  end

  describe "#update" do
    let(:attributes) { {'name' => 'some_random_value'} }
    let(:params) { attributes.merge :id => hdfs_data_source }
    let(:fake_data_source) { Object.new }

    it "checks authorization and presents the updated hadoop data source" do
      mock(Hdfs::DataSourceRegistrar).update!(hdfs_data_source.id, attributes, @user) { fake_data_source }
      it_uses_authorization(:edit, hdfs_data_source)
      mock_present { |data_source| data_source.should == fake_data_source }
      put :update, params
    end

    context "when it fails due to validation" do
      let(:attributes) { {'name' => 'some_wrong_value'} }

      before do
        mock(Hdfs::DataSourceRegistrar).update!(hdfs_data_source.id, attributes, @user) do
          raise(ActiveRecord::RecordInvalid.new(hdfs_data_source))
        end
      end

      it "responds with validation error" do
        put :update, params
        response.code.should == "422"
      end
    end
  end

  describe "#index" do
    it "presents all hadoop data sources" do
      mock_present { |models| models.to_a.should =~ HdfsDataSource.all.to_a }
      get :index
    end

    it_behaves_like "a paginated list"
    it_behaves_like :succinct_list

    context "when job_tracker is true" do
      it "returns only the hdfs data sources with job tracker info" do
        get :index, :job_tracker => true
        decoded_response.each do |data_source|
          data_source.job_tracker_host.should be_present
          data_source.job_tracker_port.should be_present
        end
      end
    end
  end

  describe "#show" do
    it "presents the hadoop data source with the given id" do
      get :show, :id => hdfs_data_source.id
      decoded_response.name.should == hdfs_data_source.name
    end

    generate_fixture "hdfsDataSource.json" do
      get :show, :id => hdfs_data_source.id
    end
  end

  describe "#destroy" do
    it "destroys the model" do
      delete :destroy, :id => hdfs_data_source.id
      response.should be_success
      HdfsDataSource.find_by_id(hdfs_data_source.id).should be_nil
    end

    it "uses authentication" do
      mock(subject).authorize! :edit, hdfs_data_source
      delete :destroy, :id => hdfs_data_source.id
    end
  end

  context 'in demo mode' do
    before do
      stub(Hdfs::DataSourceRegistrar).verify_accessibility!.with_any_args { true }
      stub(Hdfs::QueryService).version_of.with_any_args { "Cloudera CDH4" }
    end

    it_behaves_like 'a protected demo mode controller' do
      let(:params) { { :id => hdfs_data_source } }
    end
  end
end
