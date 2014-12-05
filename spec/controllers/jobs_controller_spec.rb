require 'spec_helper'
require 'will_paginate/array'

describe JobsController do
  let(:user) { users(:owner) }
  let(:workspace) { workspaces(:public) }

  before do
    log_in user
  end

  describe "#index" do
    it "responds with jobs but without their associated tasks" do
      get :index, :workspace_id => workspace.id
      response.code.should == "200"
      decoded_response[0][:tasks].should be_nil
    end

    it "sorts by name by default" do
      get :index, :workspace_id => workspace.id
      names = decoded_response.map { |job| job.name }
      names.should == names.sort
    end

    it "sorts by next run" do
      get :index, :workspace_id => workspace.id, :order => "next_run"
      timestamps = decoded_response.map { |job| job.next_run }
      timestamps.compact.should == timestamps.compact.sort
    end

    describe "pagination" do
      let(:sorted_jobs) { workspace.jobs.sort_by! { |job| job.name.downcase } }

      it "defaults the per_page to fifty" do
        get :index, :workspace_id => workspace.id
        request.params[:per_page].should == 50
      end

      it "paginates the collection" do
        get :index, :workspace_id => workspace.id, :page => 1, :per_page => 2
        decoded_response.length.should == 2
      end

      it "defaults to page one" do
        get :index, :workspace_id => workspace.id, :per_page => 2
        decoded_response.length.should == 2
        decoded_response.first.id.should == sorted_jobs.first.id
      end

      it "accepts a page parameter" do
        get :index, :workspace_id => workspace.id, :page => 2, :per_page => 2
        decoded_response.length.should == 2
        decoded_response.first.id.should == sorted_jobs[2].id
        decoded_response.last.id.should == sorted_jobs[3].id
      end
    end

    generate_fixture "jobSet.json" do
      get :index, :workspace_id => workspace.id
    end
  end

  describe '#show' do
    let(:job) { jobs(:default) }

    it "responds with a job and its associated tasks" do
      get :show, :workspace_id => workspace.id, :id => job.id
      response.code.should == "200"
      decoded_response[:id].should == job.id
      decoded_response[:tasks].should_not be_nil
    end

    generate_fixture "job.json" do
      get :show, :workspace_id => workspace.id, :id => job.id
    end
  end

  describe '#create' do
    let(:planned_job) { FactoryGirl.attributes_for(:job, :workspace => workspace) }

    let(:params) do
      {
          :workspace_id => workspace.id,
          :job => planned_job
      }
    end

    it "uses authorization" do
      mock(subject).authorize! :can_edit_sub_objects, workspace
      post :create, params
    end

    it "returns 201" do
      post :create, params
      response.code.should == "201"
    end

    it "creates a Job" do
      expect do
        post :create, params
      end.to change(Job, :count).by(1)
    end

    it "sets the owner to the creating user" do
      post :create, params
      Job.last.owner.should == user
    end

    describe "notification recipients" do
      let(:success_recipient) { FactoryGirl.create(:user).tap {|user| workspace.members << user} }
      let(:failure_recipient) { FactoryGirl.create(:user).tap {|user| workspace.members << user} }

      it "sets success and failure notification recipientship for all ids" do
        planned_job[:success_recipients] = [success_recipient.id]
        planned_job[:failure_recipients] = [failure_recipient.id]
        post :create, params
        job = Job.last
        job.success_recipients.should == [success_recipient]
        job.failure_recipients.should == [failure_recipient]
      end
    end

    it "adds a created Job with a given Workspace" do
      expect do
        post :create, params
      end.to change { workspace.reload.jobs.count }.by(1)
    end

    it 'renders the created job as JSON' do
      post :create, params
      response.code.should == "201"
      decoded_response.should_not be_empty
    end

    context "on demand" do
      let(:params) {
        {
          :job => {
            :workspace => {:id => workspace.id},
            :name => "asd",
            :interval_unit => "on_demand",
            :interval_value => "0",
            :next_run => false,
            :end_run => false,
            :time_zone => "Hawaii"
          },
          :workspace_id => workspace.id
        }
      }

      it "creates an on demand job" do
        expect do
          post :create, params
        end.to change(Job, :count).by(1)
      end
    end

    context 'with an invalid next_run' do
      let(:params) {
        {
            :job => {
                :workspace => {:id => workspace.id},
                :name => "asd",
                :interval_unit => "hours",
                :interval_value => "1",
                :next_run => "2000-07-30T14:00:00-07:00",
                :end_run => false,
                :time_zone => "Hawaii"
            },
            :workspace_id => workspace.id
        }
      }
      it 'returns a 422' do
        post :create, params
        response.code.should == "422"
      end
    end
  end

  describe '#update' do
    let(:job) { FactoryGirl.create(:job, workspace: workspace, enabled: false) }
    let(:planned_changes) do
      {
          enabled: true,
          next_run: "2020-07-30T14:00:00-00:00",
          end_run: false,
          time_zone: 'Arizona',
      }
    end

    let(:params) do
      {
        id: job.id,
        workspace_id: workspace.id,
        job: planned_changes
      }
    end

    it "uses authorization" do
      mock(subject).authorize! :can_edit_sub_objects, workspace
      put :update, params
    end

    it "updates a job" do
      expect do
        put :update, params
        job.reload
      end.to change(job, :enabled).from(false).to(true)
    end

    describe 'changing the owner' do
      let(:new_owner) { users(:the_collaborator) }
      let(:planned_changes) { {:owner_id => new_owner.id} }

      it 'checks access when updating the owner' do
        mock(subject).can?(:update_owner, job) { true }
        expect do
          put :update, params
          job.reload
        end.to change(job, :owner).from(job.owner).to(new_owner)
      end

      it 'does not change the owner if not authorized' do
        mock(subject).can?(:update_owner, job) { false }
        expect do
          put :update, params
          job.reload
        end.to_not change(job, :owner)
      end
    end

    it "applies the passed-in time zone to the passed-in next_run without shifting time" do
      put :update, params
      job.reload.next_run.to_i.should == DateTime.parse("2020-07-30T14:00:00-07:00").to_i
    end

    describe "notification recipients" do
      let(:success_recipient) { FactoryGirl.create(:user).tap {|user| workspace.members << user} }
      let(:failure_recipient) { FactoryGirl.create(:user).tap {|user| workspace.members << user} }
      let(:planned_changes) do
        {
            :success_recipients => [success_recipient.id],
            :failure_recipients => []
        }
      end
      before do
        job.notify_on :failure, workspace.members.first
      end

      it "re-sets success and failure notification recipientship, clearing old recipients" do
        post :update, params

        job.success_recipients.should == [success_recipient]
        job.failure_recipients.should == []
      end
    end

    context "when an end-run is specified" do
      let(:params) do
        {
          id: job.id,
          workspace_id: workspace.id,
          job: {
            enabled: true,
            next_run: "2020-07-30T11:00:00-00:00",
            end_run: "2020-07-30T14:00:00-00:00",
            time_zone: 'Arizona',
          }
        }
      end

      it "applies the passed-in time zone to the passed-in end_run without shifting time" do
        put :update, params
        job.reload.end_run.to_i.should == DateTime.parse("2020-07-30T14:00:00-07:00").to_i
      end
    end

    context 'with an invalid next_run' do
      let(:params) do
        {
            id: job.id,
            workspace_id: workspace.id,
            job: {
                enabled: true,
                next_run: "2000-07-30T14:00:00-00:00",
                end_run: false,
                time_zone: 'Arizona',
            }
        }
      end

      it 'returns a 422' do
        post :update, params
        response.code.should == "422"
      end
    end

    describe 'requesting a reorder' do
      let(:ids) { %w(1 2 3) }
      let(:params) do
        {
            id: job.id,
            workspace_id: workspace.id,
            job: {task_id_order: ids}
        }
      end

      it "passes the desired id order to the job" do
        any_instance_of(Job) { |job| mock(job).reorder_tasks(ids.map(&:to_i)) }
        post :update, params
      end
    end
  end

  describe '#destroy' do
    let(:job) { jobs(:default) }
    let(:params) do
      { workspace_id: workspace.id, id: job.id }
    end

    it "lets a workspace member soft delete an job" do
      delete :destroy, params
      response.should be_success
      job.reload.deleted?.should be_true
    end

    it "uses authorization" do
      mock(controller).authorize!(:can_edit_sub_objects, workspace)
      delete :destroy, params
    end
  end

  describe '#run' do
    let(:job) { FactoryGirl.create(:job, workspace: workspace, enabled: false) }

    it 'uses authorization and enqueues the job' do
      mock(controller).authorize!(:can_edit_sub_objects, workspace)
      mock(QC.default_queue).enqueue_if_not_queued('Job.run', job.id)
      post :run, :id => job.id
    end

    it 'returns a 202' do
      post :run, :id => job.id
      response.code.should == '202'
    end

    it 'presents the job' do
      post :run, :id => job.id
      decoded_response[:id].should == job.id
      decoded_response[:status].should == Job::ENQUEUED
    end

    context 'when the job is not idle' do
      let(:job) { FactoryGirl.create(:job, workspace: workspace, enabled: false, status: 'running') }

      it 'is unprocessable' do
        post :run, :id => job.id
        response.should be_unprocessable
      end
    end
  end

  describe '#stop' do
    let(:job) { FactoryGirl.create(:job, workspace: workspace, enabled: false) }

    it 'uses authorization and kills the job' do
      mock(controller).authorize!(:can_edit_sub_objects, workspace)
      any_instance_of(Job) { |job| mock(job).kill }
      post :stop, :id => job.id
    end

    it 'returns a 202' do
      post :stop, :id => job.id
      response.code.should == '202'
    end

    it 'presents the job' do
      post :stop, :id => job.id
      decoded_response[:id].should == job.id
      decoded_response[:status].should == Job::STOPPING
    end
  end

  context 'in demo mode' do
    it_behaves_like 'a protected demo mode controller' do
      let(:job) { FactoryGirl.create(:job, workspace: workspace, enabled: false) }
      let(:planned_changes) do
        {
            enabled: true,
            next_run: "2020-07-30T14:00:00-00:00",
            end_run: false,
            time_zone: 'Arizona',
        }
      end

      let(:params) do
        {
            id: job.id,
            workspace_id: workspace.id,
            job: planned_changes
        }
      end
    end
  end

  context 'when License#limit_jobs? is true' do
    let(:job) { jobs(:default) }

    before do
      stub(License.instance).limit_jobs? { true }
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
      put :update, {:workspace_id => workspace.id, :id => job.id}
      response.should be_forbidden_by_license
    end

    it 'forbids #destroy' do
      delete :destroy, {:workspace_id => workspace.id, :id => job.id}
      response.should be_forbidden_by_license
    end

    it 'forbids #run' do
      post :run, :id => job.id
      response.should be_forbidden_by_license
    end

    it 'forbids #stop' do
      post :stop, :id => job.id
      response.should be_forbidden_by_license
    end
  end
end
