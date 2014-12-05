require 'spec_helper'

describe JdbcDataset do
  let(:dataset) { datasets(:jdbc_table) }

  describe '#data_source_account_ids' do
    it 'returns data source account ids with access to the schema' do
      dataset.data_source_account_ids.should == dataset.schema.data_source_account_ids
    end
  end

  describe '#all_rows_sql' do
    let(:expected) { %{SELECT * FROM "#{dataset.schema.name}"."#{dataset.name}"} }

    it 'builds generic select * from qualified table name' do
      dataset.all_rows_sql.strip.should == expected
    end
  end

  describe '#execution_location' do
    it 'is the jdbc data source' do
      dataset.execution_location.should == dataset.data_source
    end
  end
end
