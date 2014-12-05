require 'spec_helper'

describe PgDataset do
  let(:dataset) { datasets(:pg_table) }

  describe '#data_source_account_ids' do
    it 'returns data source account ids with access to the database' do
      dataset.data_source_account_ids.should == dataset.database.data_source_account_ids
    end
  end

  describe '#execution_location' do
    it 'returns the parent database' do
      dataset.execution_location.should == dataset.database
    end
  end

  describe '#database_name' do
    it 'returns the parent database name' do
      dataset.database_name.should == dataset.database.name
    end
  end

  describe '#column_type' do
    it 'is PgDatasetColumn' do
      dataset.column_type.should == 'PgDatasetColumn'
    end
  end

  describe 'importability', :postgres_integration do
    let(:schema) { PgSchema.find_by_name('test_schema') }
    let(:source) { schema.datasets.find_by_name('base_table1') }

    it_behaves_like 'an importable dataset'
  end
end
