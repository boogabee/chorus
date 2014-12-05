require 'spec_helper'

describe JobTaskResult do
  describe "validations" do
    it { should ensure_inclusion_of(:status).in_array(JobTaskResult::VALID_STATUSES) }
  end

  describe "#finish" do
    let(:result) { JobTaskResult.new }

    it "sets finished_at to now" do
      Timecop.freeze {
        result.finish(:status => JobTaskResult::SUCCESS)
        result.finished_at.should == Time.current
      }
    end

    it "mass assigns attributes" do
      result.finish(:status => JobTaskResult::SUCCESS, :payload_id => 3, :payload_result_id => '1234')
      result.status.should == JobTaskResult::SUCCESS
      result.payload_id.should == 3
      result.payload_result_id.should == '1234'
    end

    it "returns the JobTaskResult" do
      result.finish(:status => JobTaskResult::SUCCESS, :payload_result_id => '1234').should == result
    end

    it "sets the message" do
      result.finish(:status => JobTaskResult::FAILURE, :message => 'omg!')
      result.message.should == 'omg!'
    end
  end
end
