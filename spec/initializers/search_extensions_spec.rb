require 'spec_helper'

describe "SunspotExtensions" do
  describe "solr_benchmark" do
    it "logs in utc" do
      Timecop.freeze do
        stub(User).logger.stub!.info.with_any_args do |message|
          message.should include(Time.current.to_s)
        end
        User.send(:solr_benchmark, 1, 1) {}
      end
    end
  end
end
