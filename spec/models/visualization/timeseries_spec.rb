require 'spec_helper'

describe Visualization::Timeseries do

  let(:schema_name) { 'test_schema' }
  let(:table_name) { 'base_table1' }

  context 'for gpdb', :greenplum_integration  do
    let(:data_source_account) { GreenplumIntegration.real_account }
    let(:database) { GreenplumIntegration.real_database }

    context 'for a table' do
      let(:dataset) { database.find_dataset_in_schema(table_name, schema_name) }

      it_behaves_like 'a timeseries visualization'
    end

    context 'for a chorus view' do
      let(:dataset) { datasets(:executable_chorus_view) }

      it_behaves_like 'a timeseries visualization'
    end

    context 'when domain values exceed limit' do
      let(:visualization) do
        Visualization::Timeseries.new(dataset, {
            :time_interval => 'month',
            :aggregation => 'sum',
            :x_axis => 'time_value',
            :y_axis => 'column1',
            :filters => filters
        })
      end
      let(:filters) { [] }
      let(:dataset) {
        d = datasets(:executable_chorus_view)
        d.update_attribute(:query, "select g as column1, (NOW() + '1 month'::INTERVAL * g) as time_value from (select generate_series(1,2000) as g) a;")
        d
      }

      before do
        set_current_user users(:default)
      end

      it 'raises an error' do
        expect {
          visualization.fetch!(data_source_account, 12345)
        }.to raise_error(ApiValidationError)
      end
    end
  end

  context 'for postgres', :postgres_integration do
    let(:data_source_account) { PostgresIntegration.real_account }
    let(:database) { PostgresIntegration.real_database }
    let(:dataset) { database.find_dataset_in_schema(table_name, schema_name) }

    it_behaves_like 'a timeseries visualization'
  end

  context 'for teradata', :jdbc_integration do
    let(:data_source_account) { JdbcIntegration.real_account }
    let(:schema) { JdbcIntegration.real_schema }
    let(:dataset) { schema.find_or_initialize_dataset(table_name) }

    it_behaves_like 'a timeseries visualization' do
      let(:filters) {
        [
            %Q{"#{dataset.name}"."time_value" > '2012-03-03 11:53:50' (Timestamp(0), Format 'yyyy-mm-ddbhh:mi:ss')},
            %Q{"#{dataset.name}"."column1" < 5}
        ]
      }
    end
  end

  #context 'for mariadb', :mariadb_integration do
  #  let(:data_source_account) { MariadbIntegration.real_account }
  #  let(:schema) { MariadbIntegration.real_schema }
  #  let(:dataset) { schema.find_or_initialize_dataset(table_name) }
  #
  #  it_behaves_like 'a timeseries visualization' do
  #    let(:filters) {
  #      [
  #          %Q{"#{dataset.name}"."time_value" > TIMESTAMP '2012-03-03 11:53:50'},
  #          %Q{"#{dataset.name}"."column1" < 5}
  #      ]
  #    }
  #  end
  #end

  context 'for oracle', :oracle_integration do
    let(:data_source_account) { OracleIntegration.real_account }
    let(:schema) { OracleIntegration.real_schema }
    let(:dataset) { schema.find_or_initialize_dataset(table_name) }

    it_behaves_like 'a timeseries visualization' do
      let(:filters) {
        [
            %Q{"#{dataset.name}"."time_value" > TIMESTAMP '2012-03-03 11:53:50'},
            %Q{"#{dataset.name}"."column1" < 5}
        ]
      }
    end
  end
end
