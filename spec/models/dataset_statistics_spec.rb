require 'spec_helper'

describe DatasetStatistics do
  context "#initialize" do
    let(:statistics) { DatasetStatistics.new({
          'description' => 'New Description',
          'column_count' => '4',
          'row_count' => '23',
          'table_type' => 'BASE_TABLE',
          'last_analyzed' => Time.parse('2012-06-06 23:02:42.40264+00'),
          'disk_size' => '230',
          'partition_count' => '2'
    })}

    it "parses the values" do
      statistics.row_count.should == 23
      statistics.table_type.should == "BASE_TABLE"
      statistics.column_count.should == 4
      statistics.description.should == 'New Description'
      statistics.last_analyzed.to_s.should == "2012-06-06 23:02:42 UTC"
      statistics.disk_size.should == 230
      statistics.partition_count.should == 2
    end
  end

  describe ".build_for" do
    context 'for a greenplum datasource' do
      let(:account) { users(:owner) }
      let(:dataset) { datasets(:table) }
      let!(:schema) { dataset.schema }
      let(:fake_statistics) {
        {
          'name' => dataset.name,
          'description' => 'table1 is cool',
          'definition' => nil,
          'column_count' => '3',
          'row_count' => '5',
          'table_type' => 'BASE_TABLE',
          'last_analyzed' => Time.parse('2012-06-06 23:02:42.40264+00'),
          'disk_size' => '500',
          'partition_count' => '6'
        }
      }

      let(:connection) { Object.new }

      before do
        stub(dataset).schema { schema }
        stub(schema).connect_with(account) { connection }
      end

      it "fills in the 'description' attribute of each db object in the relation" do
        mock(connection).metadata_for_dataset(dataset.name) { fake_statistics }
        mock(connection).partitions_disk_size(dataset.name) { 43 }
        mock.proxy(DatasetStatistics).new(fake_statistics)
        DatasetStatistics.build_for(dataset, account).should be_a(DatasetStatistics)
      end

      it "adds the partition size to the disk size" do
        mock(connection).metadata_for_dataset(dataset.name) { fake_statistics }
        mock(connection).partitions_disk_size(dataset.name) { 43 }
        stats = DatasetStatistics.build_for(dataset, account)
        stats.disk_size.should == 543
      end

      it "returns nil when metadata returns nil" do
        mock(connection).metadata_for_dataset(dataset.name) { nil }
        DatasetStatistics.build_for(dataset, account).should be_nil
      end

      it "handles nil last analyzed values (for views)" do
        mock(connection).metadata_for_dataset(dataset.name) { fake_statistics.merge('last_analyzed' => nil) }
        mock(connection).partitions_disk_size(dataset.name) { 43 }
        DatasetStatistics.build_for(dataset, account).last_analyzed.should be_nil
      end

      context "for a ChorusView" do
        let(:chorus_view) { FactoryGirl.build(:chorus_view, :schema => schema, :query => "select 1, 2, 3, 4, 5") }

        before do
          stub(connection).prepare_and_execute_statement('select 1, 2, 3, 4, 5' ,:describe_only => true) {
            obj = Object.new
            stub(obj).columns { obj }
            stub(obj).count { 5 }
            obj
          }
        end

        it "retrieves the column count" do
          DatasetStatistics.build_for(chorus_view, account).column_count.should == 5
        end
      end
    end

    context "for Hdfs Datasets" do
     let(:dataset) { datasets(:hadoop) }

     it 'retreives the file_mask' do
       DatasetStatistics.build_for(dataset, nil).file_mask.should == dataset.file_mask
     end
    end
  end
end
