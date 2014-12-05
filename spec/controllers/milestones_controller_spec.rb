require 'spec_helper'
require 'will_paginate/array'

describe MilestonesController do
  let(:user) { users(:owner) }
  let(:workspace) { workspaces(:public) }

  before do
    log_in user
  end

  describe "#index" do
    it "responds with milestones" do
      get :index, :workspace_id => workspace.id
      response.code.should == "200"
      decoded_response.length.should be > 1
      decoded_response.length.should == workspace.milestones.count
    end

    it "sorts by target date by default" do
      get :index, :workspace_id => workspace.id
      target_dates = decoded_response.map { |milestone| milestone.target_date }
      target_dates.should == target_dates.sort
    end

    generate_fixture "milestoneSet.json" do
      get :index, :workspace_id => workspace.id
    end
  end

  describe '#create' do
    let(:params) {
      {
        :workspace_id => workspace.id,
        :milestone => {
          :name => 'cool milestone',
          :target_date => '2020-07-30T14:00:00-07:00'
        }
      }
    }

    it 'creates a new milestone from the params' do
      expect {
        post :create, params
      }.to change(Milestone, :count).by(1)

      Milestone.last.name.should == 'cool milestone'
    end

    it 'renders the created job as JSON' do
      post :create, params
      response.code.should == '201'
      decoded_response.should_not be_empty
    end
  end

  describe '#destroy' do
    let(:milestone) { milestones(:default) }
    let(:params) do
      { workspace_id: workspace.id, id: milestone.id }
    end

    it "lets a workspace member delete a milestone" do
      expect {
        delete :destroy, params
      }.to change(Milestone, :count).by(-1)
      response.should be_success
    end

    it "uses authorization" do
      mock(controller).authorize!(:can_edit_sub_objects, workspace)
      delete :destroy, params
    end
  end

  describe '#update' do
    let(:milestone) { milestones(:default) }
    let(:params) do
      {
        workspace_id: workspace.id,
        id: milestone.id,
        milestone: {
          state: 'achieved',
          name: 'some new name'
        }
      }
    end

    it 'updates the milestone' do
      expect {
        put :update, params
        milestone.reload
      }.to change(milestone, :state).from('planned').to('achieved')
      response.should be_success
    end

    it 'uses authorization' do
      mock(subject).authorize! :can_edit_sub_objects, workspace
      put :update, params
    end
  end

  context 'when License#limit_milestones? is true' do
    let(:milestone) { milestones(:default) }

    before do
      stub(License.instance).limit_milestones? { true }
    end

    it 'forbids #index' do
      get :index, :workspace_id => workspace.id
      response.should be_forbidden_by_license
    end

    it 'forbids #create' do
      post :create, {:workspace_id => workspace.id}
      response.should be_forbidden_by_license
    end

    it 'forbids #update' do
      put :update, {:workspace_id => workspace.id, :id => milestone.id}
      response.should be_forbidden_by_license
    end

    it 'forbids #destroy' do
      delete :destroy, {:workspace_id => workspace.id, :id => milestone.id}
      response.should be_forbidden_by_license
    end
  end
end
