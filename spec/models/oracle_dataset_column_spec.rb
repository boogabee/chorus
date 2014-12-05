require 'spec_helper'

describe OracleDatasetColumn do
  describe ".columns_for" do
    subject { described_class.columns_for(account, dataset) }

    let(:connection) { Object.new }
    let(:account) { Object.new }
    let(:dataset) { OpenStruct.new({:name => 'hiya_bob', :query_setup_sql => "select yo from bar;", :column_type => "OracleDatasetColumn"}) }
    let(:column_with_stats) do
      [
          {
              :attname => 'id',
              :format_type => 'integer',
              :description => nil,
          },
          {
              :attname => 'column1',
              :format_type => 'integer',
              :description => 'comment on column1',
          },
          {
              :attname => 'timecolumn',
              :format_type => 'timestamp without time zone',
              :description => 'comment on timecolumn',
          }
      ]
    end

    before do
      stub(connection).column_info(dataset.name, dataset.query_setup_sql) { column_with_stats }
      stub(dataset).connect_with(account) { connection }
    end

    it "returns oracle specific columns" do
      subject.first.should be_a OracleDatasetColumn
    end

    it "gets the column information for table users" do
      subject.count.should == 3
      column1 = subject[1]

      column1.name.should eq('column1')
      column1.data_type.should eq('integer')
      column1.description.should == 'comment on column1'
      column1.ordinal_position.should eq(2)
    end

    it "returns no column statistics for table users" do
      column1 = subject[1]
      column1.statistics.should be_nil
    end
  end

  describe "#supported?" do
    subject do
      OracleDatasetColumn.new(:name => "column_name",
                              :ordinal_position => 1,
                              :description => "description")
    end

    context "when the column data type is supported" do
      %w{CHAR DATE TIMESTAMP(6) ROWID NVARCHAR2 VARCHAR INT CHAR LONG}.each do |type|
        it "returns true for #{type}" do
          subject.data_type = type
          subject.should be_supported
        end
      end
    end

    context "when the column data type is unsupported" do
      %w{MLSLABEL BFILE RAW BLOB}.each do |type|
        it "returns false for #{type}" do
          subject.data_type = type
          subject.should_not be_supported
        end
      end
    end
  end
end
