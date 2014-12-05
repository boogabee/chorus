require 'spec_helper'

describe HdfsDatasetStatisticsPresenter, :type => :view do
  let(:statistics) { FactoryGirl.build(:hdfs_dataset_statistics) }

  describe "#to_hash" do
    subject { described_class.new(statistics, view) }

    it "includes the fields" do
      hash = subject.to_hash

      hash[:file_mask].should == 'A file mask'
    end
  end
end