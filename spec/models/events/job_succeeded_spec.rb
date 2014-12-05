require 'spec_helper'
require_relative 'job_finished_shared_behaviors'

describe Events::JobSucceeded do
  let(:job) { jobs(:default) }
  let(:workspace) { job.workspace }
  let(:owner) { job.owner }
  let(:member) { users(:the_collaborator) }
  let!(:no_emails_member) { user = FactoryGirl.create(:user, subscribed_to_emails: false); workspace.members << user; user }
  let(:non_member) { users(:no_collaborators) }
  let(:job_result) { job_results(:default) }
  let(:event) { Events::JobSucceeded.by(owner).add(:job => job, :workspace => workspace, :job_result => job_result) }

  it_behaves_like 'a job finished event', 'success', :success_notify

  describe 'header' do
    it "has good copy" do
      event.header.should == "Job #{job.name} succeeded in workspace #{workspace.name}."
    end
  end
end