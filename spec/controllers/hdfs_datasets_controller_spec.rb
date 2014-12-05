require "spec_helper"

describe HdfsDatasetsController do
  let(:user) { users(:owner) }
  let(:workspace) { workspaces(:public) }

  before do
    log_in user
    any_instance_of(HdfsDataset) do |ds|
      stub(ds).contents { ["content"] }
    end
  end

  describe '#create' do
    let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }
    let(:params) do
      {:hdfs_dataset => {
          :file_mask => 'foo/*/bar',
          :data_source_id => hdfs_data_source.id,
          :workspace_id => workspace.id,
          :name => Faker::Name.name
      }}
    end

    before do
      set_current_user(user)
    end

    it 'creates a Hadoop dataset from a file mask & data source' do
      expect {
        post :create, params
      }.to change { HdfsDataset.count }.by(1)
    end

    it 'renders the created dataset as JSON' do
      post :create, params
      response.code.should == "201"
      decoded_response.should_not be_empty
    end

    it "uses authorization" do
      mock(subject).authorize! :can_edit_sub_objects, workspace
      post :create, params
    end

    it 'makes a HdfsDatasetCreated event' do
      expect {
        post :create, params
      }.to change(Events::HdfsDatasetCreated, :count).by(1)
      event = Events::HdfsDatasetCreated.by(user).last
      event.workspace.id.should == params[:hdfs_dataset][:workspace_id]
      event.dataset.name.should == params[:hdfs_dataset][:name]
      event.action.should == "HdfsDatasetCreated"
    end
  end

  describe '#update' do
    let(:dataset) { datasets(:hadoop) }
    let!(:old_name) { dataset.name }
    let(:new_name) { 'Cephalopodiatry' }

    before do
      set_current_user(user)
    end

    it "updates the attributes of the appropriate hdfs Dataset" do
      expect {
        put :update, :name => new_name, :id => dataset.id
      }.to change { dataset.reload.name }.from(old_name).to(new_name)
    end

    it "uses authorization" do
      mock(subject).authorize! :can_edit_sub_objects, workspace
      put :update, :name => new_name, :id => dataset.id
    end

    it 'makes a HdfsDatasetUpdated event' do
      expect {
        put :update, :name => new_name, :id => dataset.id
      }.to change(Events::HdfsDatasetUpdated, :count).by(1)
      event = Events::HdfsDatasetUpdated.by(user).last
      event.workspace.id.should == dataset.reload.workspace.id
      event.dataset.name.should == new_name
      event.action.should == "HdfsDatasetUpdated"
    end
  end

  describe '#destroy' do
    let(:dataset) { datasets(:hadoop) }

    it "uses authorization" do
      mock(controller).authorize!(:can_edit_sub_objects, workspace)
      delete :destroy, :id => dataset.id
    end

    it "lets a workspace member soft delete an hdfs dataset" do
      delete :destroy, :id => dataset.to_param
      response.should be_success
      dataset.reload.deleted?.should be_true
    end
  end
end