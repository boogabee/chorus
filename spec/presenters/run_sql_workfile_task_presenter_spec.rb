require 'spec_helper'

describe RunSqlWorkfileTaskPresenter, :type => :view do
  let(:user) { users(:owner) }
  let(:job) { jobs(:default) }
  let(:workspace) { job.workspace }
  let(:job_task) { job_tasks(:rswt) }
  let(:presenter) { RunSqlWorkfileTaskPresenter.new(job_task, view) }

  before(:each) { set_current_user(user) }

  describe '#to_hash' do
    let(:hash) { presenter.to_hash }
    let(:keys) { [:id, :job, :action, :index, :name] }

    it 'includes the right keys' do
      keys.each do |key|
        hash.should have_key(key)
      end
    end
  end
end
