require 'spec_helper'

describe ColumnsController do
  ignore_authorization!

  before do
    log_in user
  end

  context '#index' do
    context 'with mock data' do
      let(:user) { users(:no_collaborators) }
      let(:table) { datasets(:table) }

      before do
        fake_account = Object.new
        stub(subject).account_for_current_user(table) { fake_account }
        stub(DatasetColumn).columns_for(fake_account, table) do
          [
              GpdbDatasetColumn.new(:name => 'email', :data_type => 'varchar(255)', :description => 'it must be present'),
              GpdbDatasetColumn.new(:name => 'age', :data_type => 'integer', :description => 'nothing'),
          ]
        end
      end

      it 'checks for permissions' do
        mock(subject).authorize! :show_contents, table.data_source
        get :index, :dataset_id => table.to_param
      end

      it_behaves_like 'a paginated list' do
        let(:params) {{ :dataset_id => table.to_param }}
      end

      it 'retrieves column for a table' do
        get :index, :dataset_id => table.to_param

        response.code.should == '200'
        decoded_response.length.should == 2
      end
    end

    context 'with real greenplum data', :greenplum_integration do
      let(:account) { GreenplumIntegration.real_account }
      let(:user) { account.owner }
      let(:database) { GreenplumIntegration.real_database }
      let(:dataset) {database.find_dataset_in_schema('base_table1', 'test_schema')}

      before do
        dataset.analyze(account)
      end

      it 'presents gpdb dataset columns' do
        mock_present do |column_set|
          column_set.first.should be_a GpdbDatasetColumn
        end
        get :index, :dataset_id => dataset.to_param
      end

      generate_fixture 'databaseColumnSet.json' do
        get :index, :dataset_id => dataset.to_param
      end

      it 'generates a column fixture', :fixture do
        get :index, :dataset_id => dataset.to_param
        save_fixture 'databaseColumn.json', { :response => response.decoded_body['response'].first }
      end
    end

    context 'with real postgres data', :postgres_integration do
      let(:account) { PostgresIntegration.real_account }
      let(:user) { account.owner }
      let(:database) { PostgresIntegration.real_database }
      let(:dataset) {database.find_dataset_in_schema('base_table1', 'test_schema')}

      before do
        dataset.analyze(account)
      end

      it 'presents pg dataset columns' do
        mock_present do |column_set|
          column_set.first.should be_a PgDatasetColumn
        end
        get :index, :dataset_id => dataset.to_param
      end

      it 'presents' do
        get :index, :dataset_id => dataset.to_param
        response.code.should == '200'
      end
    end

    context 'with real oracle data', :oracle_integration do
      let(:user) { users(:owner) }
      let(:account) { OracleIntegration.real_account }
      let(:schema) { OracleIntegration.real_schema }
      let(:data_source) { OracleIntegration.real_data_source }
      let(:dataset) { schema.datasets.find_by_name('TWO_COLUMN_TABLE') }

      before do
        schema.refresh_datasets(data_source.owner_account)
      end

      it 'presents oracle dataset columns' do
        mock_present do |column_set|
          column_set.first.should be_a OracleDatasetColumn
        end
        get :index, :dataset_id => dataset.to_param
      end
    end

    context 'with real jdbc data', :jdbc_integration do
      let(:user) { users(:owner) }
      let(:account) { JdbcIntegration.real_account }
      let(:schema) { JdbcIntegration.real_schema }
      let(:data_source) { JdbcIntegration.real_data_source }
      let(:dataset) { schema.datasets.find_by_name('TWO_COLUMN_TABLE') }

      before do
        schema.refresh_datasets(data_source.owner_account)
      end

      it 'presents jdbc dataset columns' do
        mock_present do |column_set|
          column_set.first.should be_a JdbcDatasetColumn
        end
        get :index, :dataset_id => dataset.to_param
      end
    end
  end
end
