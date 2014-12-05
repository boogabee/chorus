require 'spec_helper'

describe JobResult do
  describe "validations" do
    it { should validate_presence_of :started_at }
    it { should validate_presence_of :finished_at }
    it { should belong_to :job }
    it { should have_many :job_task_results }
  end
end