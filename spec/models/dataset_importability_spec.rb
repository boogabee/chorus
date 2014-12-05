require 'spec_helper'

describe DatasetImportability do

  context 'with an Oracle dataset' do
    let(:data_source_account) { dataset.schema.data_source.owner_account }
    let(:supported_column) { DatasetColumn.new(data_type: "BINARY_DOUBLE", name: "supported_col") }
    let(:unsupported_column) { DatasetColumn.new(data_type: "RAINBOWS", name: "unsupported_col") }

    let(:dataset) { datasets(:oracle_table) }
    let(:importability) { DatasetImportability.new(dataset) }

    before do
      stub(DatasetColumn).columns_for(data_source_account, dataset) { columns }
    end

    context "when all of the dataset's columns are of a supported type" do
      let(:columns) { [supported_column] }

      it 'responds that the dataset is importable' do
        importability.should be_importable
      end
    end

    context "when the dataset contains columns with unsupported types" do
      let(:columns) { [supported_column, unsupported_column] }

      it 'responds that the dataset is unimportable' do
        importability.should_not be_importable
      end

      it 'identifies unsupported columns' do
        importability.invalid_columns.should ==
          [{
             column_name: 'unsupported_col',
             column_type: 'RAINBOWS'
           }]
      end

      it 'lists the supported column types' do
        importability.supported_column_types.should == ['BINARY_DOUBLE', 'BINARY_FLOAT', 'CHAR', 'CLOB', 'DATE', 'LONG', 'DECIMAL', 'FLOAT', 'INT', 'NCHAR', 'NCLOB', 'NUMBER', 'NVARCHAR2', 'ROWID', 'TIMESTAMP', 'UROWID', 'VARCHAR', 'VARCHAR2', 'TIMESTAMP WITH TIME ZONE', 'TIMESTAMP WITH LOCAL TIME ZONE']
      end
    end
  end

  context 'with a GpdbDataset or a PgDataset' do
    it 'is importable' do
      [GpdbTable, GpdbView, ChorusView, PgTable, PgView].each do |clazz|
        described_class.new(clazz.new).should be_importable
      end
    end
  end
end
