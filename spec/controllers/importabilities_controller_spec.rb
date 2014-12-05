require 'spec_helper'

describe ImportabilitiesController do
  let(:user) { users(:default) }
  let(:data_source_account) { dataset.schema.data_source.owner_account }

  let(:supported_column) { DatasetColumn.new(data_type: "BINARY_DOUBLE", name: "supported_col") }
  let(:unsupported_column) { DatasetColumn.new(data_type: "RAINBOWS", name: "unsupported_col") }

  let(:dataset) { datasets(:oracle_table) }

  before do
    log_in user
  end

  describe "#show" do
    before do
      stub(DatasetColumn).columns_for(data_source_account, dataset) { columns }
    end

    context "when all of the dataset's columns are of a supported type" do
      let(:columns) { [supported_column] }

      it 'responds that the dataset is importable' do
        get :show, :dataset_id => dataset.to_param
        decoded_response.importability.should == true
      end

      it 'does not include invalid_columns or supported_column_types in the response' do
        get :show, :dataset_id => dataset.to_param
        decoded_response.keys.should_not include('invalid_columns')
        decoded_response.keys.should_not include('supported_column_types')
      end

      generate_fixture "datasetImportability.json" do
        get :show, :dataset_id => dataset.to_param
      end
    end

    context 'when the dataset contains columns with unsupported types' do
      let(:columns) { [supported_column, unsupported_column] }

      it 'responds that the dataset is unimportable' do
        get :show, :dataset_id => dataset.to_param
        decoded_response.importability.should == false
      end

      it 'identifies unsupported columns' do
        get :show, :dataset_id => dataset.to_param
        decoded_response.invalid_columns.should == ['unsupported_col (RAINBOWS)']
      end

      it 'lists the supported columns' do
        get :show, :dataset_id => dataset.to_param
        decoded_response.supported_column_types.should =~ ['BINARY_DOUBLE', 'BINARY_FLOAT', 'CHAR', 'CLOB', 'DATE', 'LONG', 'DECIMAL', 'FLOAT', 'INT', 'NCHAR', 'NCLOB', 'NUMBER', 'NVARCHAR2', 'ROWID', 'TIMESTAMP', 'UROWID', 'VARCHAR', 'VARCHAR2', 'TIMESTAMP WITH TIME ZONE', 'TIMESTAMP WITH LOCAL TIME ZONE']
      end

      generate_fixture 'datasetImportabilityForUnimportableDataset.json' do
        get :show, :dataset_id => dataset.to_param
      end
    end
  end
end
