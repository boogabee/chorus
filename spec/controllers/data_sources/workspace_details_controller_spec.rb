require 'spec_helper'

describe DataSources::WorkspaceDetailsController do
  ignore_authorization!

  let(:user) { users(:owner) }

  before do
    log_in user
    any_instance_of(GpdbSchema) do |schema|
      stub(schema).disk_space_used(anything) { 100000000 }
    end
  end

  describe "#show" do
    let(:data_source) { data_sources(:owners) }

    context "with a valid data source id" do
      it "does not require authorization" do
        dont_allow(subject).authorize!.with_any_args
        get :show, :data_source_id => data_source.to_param
        response.should be_success
      end

      it "presents the gpdb data source workspace details" do
        mock.proxy(DataSourceWorkspaceDetailPresenter).new(data_source, anything, {})
        get :show, :data_source_id => data_source.to_param
      end

      generate_fixture "dataSourceDetails.json" do
        get :show, :data_source_id => data_source.to_param
      end
    end

    context "with an invalid gpdb data source id" do
      it "returns not found" do
        get :show, :data_source_id => 'invalid'
        response.should be_not_found
      end
    end

    context "when the user does not have access to the data source" do
      let(:user) { users(:not_a_member) }
      generate_fixture "dataSourceDetailsWithoutPermission.json" do
        get :show, :data_source_id => data_source.to_param
      end
    end

    context 'with a postgres data source' do
      let(:data_source) { data_sources(:postgres) }

      it 'presents the workspace details' do
        mock.proxy(DataSourceWorkspaceDetailPresenter).new(data_source, anything, {})
        get :show, :data_source_id => data_source.to_param
        response.code.should == '200'
      end
    end
  end
end
