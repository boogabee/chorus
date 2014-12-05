require 'spec_helper'

describe HdfsDatasetStatistics do
  describe '#initialize' do
    let(:file_mask) { 'A file mask' }

    let(:statistics) do
      described_class.new({ 'file_mask' => file_mask })
    end

    it "parses the values" do
      statistics.file_mask.should == file_mask
    end
  end
end