require 'spec_helper'

describe HdfsEntryStatistics do
  context "#initialize" do

    let(:statistics) {
      HdfsEntryStatistics.new(response)
    }

    let(:response) {
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

    it "parses the values" do
      statistics.owner.should == 'the_boss'
      statistics.group.should == 'the_group'
      statistics.modified_at.to_s.should == "2012-06-06 23:02:42 -0700"
      statistics.accessed_at.to_s.should == "2012-06-06 23:02:42 -0700"
      statistics.file_size.should == 1234098
      statistics.block_size.should == 128
      statistics.permissions.should == 'rw-r--r--'
      statistics.replication.should == 3
    end
  end
end
