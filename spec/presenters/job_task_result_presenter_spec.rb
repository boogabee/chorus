require 'spec_helper'

describe JobTaskResultPresenter, :type => :view do
  describe '#to_hash' do
    let(:task_result) { FactoryGirl.create(:job_task_result) }
    let(:presenter) { JobTaskResultPresenter.new(task_result, view) }
    let(:hash) { presenter.to_hash }
    let(:keys) { [:status, :started_at, :finished_at, :name, :message, :id, :payload_result_id, :payload_id] }

    it "includes the right keys" do
      keys.each { |key| hash.should have_key(key) }
    end
  end
end