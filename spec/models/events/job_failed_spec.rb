require 'spec_helper'
require_relative 'job_finished_shared_behaviors'

describe Events::JobFailed do
  let(:job) { jobs(:default) }
  let(:workspace) { job.workspace }
  let(:owner) { job.owner }
  let(:member) { users(:the_collaborator) }
  let!(:no_emails_member) { user = FactoryGirl.create(:user, subscribed_to_emails: false); workspace.members << user; user }
  let(:non_member) { users(:no_collaborators) }
  let(:job_result) { FactoryGirl.create(:job_result, :job => job, :succeeded => false) }
  let(:event) { Events::JobFailed.by(owner).add(:job => job, :workspace => workspace, :job_result => job_result) }

  it_behaves_like 'a job finished event', 'failure', :failure_notify

  describe 'header' do
    it "has good copy" do
      event.header.should == "Job #{job.name} failed in workspace #{workspace.name}."
    end
  end
end