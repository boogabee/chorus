require 'spec_helper'

describe HdfsEntryStatisticsPresenter, :type => :view do
  let(:options) {{}}
  let(:details) {
    OpenStruct.new(
      'owner' => 'the_boss',
      'group' => 'the_group',
      'modified_at' => Time.parse('2012-06-06 23:02:42'),
      'accessed_at' => Time.parse('2012-06-06 23:02:42'),
      'size' => 1234098,
      'block_size' => 128,
      'permissions' => 'rw-r--r--',
      'replication' => 3
    )
  }
  let(:statistics) { HdfsEntryStatistics.new(details) }
  let(:presenter) { HdfsEntryStatisticsPresenter.new(statistics, view, options) }

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    context "for a file" do
      it "includes the fields" do
        hash[:owner].should == 'the_boss'
        hash[:group].should == 'the_group'
        hash[:modified_at].should == "2012-06-06 23:02:42 -0700"
        hash[:accessed_at].should == "2012-06-06 23:02:42 -0700"
        hash[:file_size].should == 1234098
        hash[:block_size].should == 128
        hash[:permissions].should == 'rw-r--r--'
        hash[:replication].should == 3
      end
    end
  end
end