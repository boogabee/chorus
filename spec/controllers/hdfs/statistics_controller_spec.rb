require "spec_helper"

describe Hdfs::StatisticsController do
  let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }
  let(:entry) { hdfs_entries(:hdfs_file) }

  before do
    log_in users(:owner)
  end

  describe "show" do

    let(:statistics) { OpenStruct.new(FactoryGirl.attributes_for(:hdfs_entry_statistics)) }

    before do
      mock(HdfsEntry).statistics(entry.path.chomp('/'), entry.hdfs_data_source) { HdfsEntryStatistics.new statistics }
    end

    it "should retrieve the statistics for an entry" do
      get :show, :hdfs_data_source_id => hdfs_data_source.id, :file_id => entry.id

      response.code.should == '200'
      decoded_response.owner.should == statistics.owner
      decoded_response.group.should == statistics.group
      decoded_response.file_size.should == statistics.size
    end

    generate_fixture "hdfsEntryStatistics.json" do
      get :show, :hdfs_data_source_id => hdfs_data_source.id, :file_id => entry.id
    end

  end

end
