require 'spec_helper'

describe JobResultPresenter, :type => :view do
  let(:job) { jobs(:default) }
  let(:job_result) { FactoryGirl.create(:job_result) }
  let(:presenter) { JobResultPresenter.new(job_result, view) }

  before do
    FactoryGirl.create(:job_task_result, :job_result => job_result)
    FactoryGirl.create(:job_task_result, :job_result => job_result)
    FactoryGirl.create(:job_task_result, :job_result => job_result)
    FactoryGirl.create(:job_task_result, :job_result => job_result)
  end

  describe '#to_hash' do
    let(:hash) { presenter.to_hash }
    let(:keys) { [:succeeded, :started_at, :finished_at, :id] }

    it "includes the right keys" do
      keys.each do |key|
        hash.should have_key(key)
      end
    end

    it "includes the job task results" do
      hash[:job_task_results].count.should == 4
    end
  end
end