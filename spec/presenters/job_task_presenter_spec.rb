require 'spec_helper'

describe JobTaskPresenter, :type => :view do
  let(:user) { users(:owner) }
  let(:job) { jobs(:default) }
  let(:workspace) { job.workspace }
  let(:job_task) { job_tasks(:default) }
  let(:presenter) { JobTaskPresenter.new(job_task, view) }

  before(:each) do
    set_current_user(user)
  end

  describe '#to_hash' do
    let(:hash) { presenter.to_hash }
    let(:keys) { [:job, :action, :index, :name, :id, :is_deleted, :is_valid] }

    it "includes the right keys" do
      keys.each do |key|
        hash.should have_key(key)
      end
    end
  end
end