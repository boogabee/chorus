require 'spec_helper'

describe Visualization::Boxplot do
  let(:schema_name) { 'test_schema' }
  let(:table_name) { 'base_table1' }

  context 'for gpdb', :greenplum_integration do
    let(:data_source_account) { GreenplumIntegration.real_account }
    let(:database) { GpdbDatabase.find_by_name_and_data_source_id(GreenplumIntegration.database_name, GreenplumIntegration.real_data_source) }

    context 'for a table' do
      let(:dataset) { database.find_dataset_in_schema(table_name, schema_name) }
      let(:all_caps_column_dataset) { database.find_dataset_in_schema('allcaps_candy', 'test_schema') }
      let(:table_with_nulls) { database.find_dataset_in_schema('table_with_nulls', 'test_schema') }

      it_behaves_like 'a boxplot visualization'
    end

    context 'for a chorus view' do
      let(:dataset) { datasets(:executable_chorus_view) }
      let(:all_caps_column_dataset) do
        ChorusView.new({:name => 'CHORUS_VIEW',
                        :schema => database.schemas.find_by_name!(schema_name),
                        :query => 'select * from allcaps_candy'
                       }, :without_protection => true)
      end
      let(:table_with_nulls) do
        ChorusView.new({:name => 'CHORUS_VIEW',
                        :schema => database.schemas.find_by_name!(schema_name),
                        :query => 'select * from table_with_nulls'
                       }, :without_protection => true)
      end

      it_behaves_like 'a boxplot visualization'
    end
  end

  context 'for postgres', :postgres_integration do
    let(:data_source_account) { PostgresIntegration.real_account }
    let(:database) { PostgresIntegration.real_database }

    let(:dataset) { database.find_dataset_in_schema(table_name, schema_name) }
    let(:all_caps_column_dataset) { database.find_dataset_in_schema('allcaps_candy', 'test_schema') }
    let(:table_with_nulls) { database.find_dataset_in_schema('table_with_nulls', 'test_schema') }

    it_behaves_like 'a boxplot visualization'
  end

  context 'for teradata', :jdbc_integration do
    let(:data_source_account) { JdbcIntegration.real_account }
    let(:schema) { JdbcIntegration.real_schema }

    let(:dataset) { schema.find_or_initialize_dataset(table_name) }
    let(:all_caps_column_dataset) { schema.find_or_initialize_dataset('allcaps_candy') }
    let(:table_with_nulls) { schema.find_or_initialize_dataset('table_with_nulls') }

    it_behaves_like 'a boxplot visualization'
  end

  #context 'for mariadb', :mariadb_integration do
  #  let(:data_source_account) { MariadbIntegration.real_account }
  #  let(:schema) { MariadbIntegration.real_schema }
  #
  #  let(:dataset) { schema.find_or_initialize_dataset(table_name) }
  #  let(:all_caps_column_dataset) { schema.find_or_initialize_dataset('allcaps_candy') }
  #  let(:table_with_nulls) { schema.find_or_initialize_dataset('table_with_nulls') }
  #
  #  it_behaves_like 'a boxplot visualization'
  #end

  context 'for oracle', :oracle_integration do
    let(:data_source_account) { OracleIntegration.real_account }
    let(:schema) { OracleIntegration.real_schema }

    let(:dataset) { schema.find_or_initialize_dataset(table_name) }
    let(:all_caps_column_dataset) { schema.find_or_initialize_dataset('allcaps_candy') }
    let(:table_with_nulls) { schema.find_or_initialize_dataset('table_with_nulls') }

    it_behaves_like 'a boxplot visualization'
  end
end
