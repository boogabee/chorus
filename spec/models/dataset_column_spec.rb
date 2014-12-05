require 'spec_helper'

describe DatasetColumn do
  describe ".columns_for" do
    subject { DatasetColumn.columns_for(account, dataset) }

    let(:connection) { Object.new }
    let(:account) { Object.new }
    let(:dataset) { OpenStruct.new({:name => 'hiya_bob', :query_setup_sql => "select yo from bar;", :column_type => "DatasetColumn"}) }

    let(:column_with_stats) do
      [
          {
              :attname => 'id',
              :format_type => 'integer',
              :description => nil
          },
          {
              :attname => 'column1',
              :format_type => 'integer',
              :description => 'comment on column1'
          },
          {
              :attname => 'timecolumn',
              :format_type => 'timestamp without time zone',
              :description => 'comment on timecolumn'
          }
      ]
    end

    before do
      stub(connection).column_info(dataset.name, dataset.query_setup_sql) { column_with_stats }
      stub(dataset).connect_with(account) { connection }
    end

    it "returns dataset columns" do
      subject.first.should be_a DatasetColumn
    end

    it "gets the column information for table users" do
      subject.count.should == 3
      column1 = subject[1]

      column1.name.should eq('column1')
      column1.data_type.should eq('integer')
      column1.description.should == 'comment on column1'
      column1.ordinal_position.should eq(2)
    end
  end

  describe '#match?' do
    let(:oracle_column) { OracleDatasetColumn.new(name: 'name', data_type: 'CHAR') }
    let(:greenplum_column) { GpdbDatasetColumn.new(name: 'name', data_type: 'character(1)') }

    context 'with an oracle and a greenplum' do
      it 'is true if their types are convertible' do
        oracle_column.match?(greenplum_column).should be_true
      end
    end

    context 'with two greenplums' do
      it 'is true if their types are the same' do
        greenplum_column.match?(greenplum_column).should be_true
      end
    end
  end
end
