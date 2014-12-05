require 'spec_helper'

describe OracleSqlResult, :oracle_integration do
  let(:data_source) { OracleIntegration.real_data_source }
  let(:account) { OracleIntegration.real_account }
  let(:db_url) { OracleIntegration.db_url }

  let(:options) do
    {
        :data_source => data_source,
        :logger => Rails.logger
    }
  end
  let(:connection) { OracleConnection.new(data_source, account, options) }

  before do
    stub.proxy(Sequel).connect.with_any_args
    options.delete(:logger)
  end

  describe "load_from_result_set" do
    let(:schema_name) { OracleIntegration.schema_name }
    let(:table_name) { "ALL_COLUMN_TABLE" }

    context "when a limit is set" do
      let(:execute_options) do
        {
            :limit => 1
        }
      end

      it "does not raise an error caused by a LONG value" do
        expect {
          connection.prepare_and_execute_statement "SELECT * FROM \"#{schema_name}\".\"#{table_name}\"", execute_options
        }.not_to raise_error
      end

    end
  end
end
