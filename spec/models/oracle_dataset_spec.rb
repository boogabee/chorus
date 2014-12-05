require 'spec_helper'

describe OracleDataset do
  let(:dataset) { datasets(:oracle_table) }

  describe "#all_rows_sql" do
    let(:schema) { OracleSchema.new(:name => "foobar")}
    let(:dataset) { OracleTable.new(:name => "table_name") }
    let(:dataset_columns) { [
        OracleDatasetColumn.new(:name => "unsupported",
                                :data_type => "MLSLABEL",
                                :ordinal_position => 1,
                                :description => "unsupported"
        ),
        OracleDatasetColumn.new(:name => "supported",
                                :data_type => "varchar",
                                :ordinal_position => 2,
                                :description => "supported")
    ] }

    before do
      dataset.schema = schema
      stub(dataset).column_data.returns(dataset_columns)
    end

    it "selects only the columns that are supported" do
      dataset.all_rows_sql.should == "SELECT 'mlslabel' AS \"unsupported\", \"supported\" FROM \"foobar\".\"table_name\""
    end
  end

  describe "#data_source_account_ids" do
    it "returns data source account ids with access to the schema" do
      dataset.data_source_account_ids.should == dataset.schema.data_source_account_ids
    end
  end

  describe "#can_import_into", :greenplum_integration, :oracle_integration do
    let(:oracle_schema) { OracleIntegration.real_schema }
    let(:gpdb_schema) { GpdbSchema.find_by_name('test_schema') }
    let(:source) { oracle_schema.datasets.find_by_name('BASE_TABLE1') }

    context "when tables have same column number, names and types" do
      let(:destination) { gpdb_schema.datasets.find_by_name('base_table2') }

      it "returns true" do
        source.can_import_into(destination).should be_true
      end
    end

    context "when tables have the same column number and types, but different names" do
      let(:destination) { gpdb_schema.datasets.find_by_name('different_names_table2') }

      it "returns false" do
        source.can_import_into(destination).should be_false
      end
    end

    context "when tables have same column number and names, but different types" do
      let(:destination) { gpdb_schema.datasets.find_by_name('different_types_table') }

      it "returns false" do
        source.can_import_into(destination).should be_false
      end
    end

    context "when tables have different number of columns" do
      let(:destination) { gpdb_schema.datasets.find_by_name('master_table1') }

      it "returns false" do
        source.can_import_into(destination).should be_false
      end
    end

    context "when the source table has unsupported columns" do
      let(:destination) { gpdb_schema.datasets.find_by_name('base_table2') }

      it "should skip matching those columns" do
        source.can_import_into(destination).should be_true
      end
    end
  end

  describe 'associable?' do
    it 'is true' do
      dataset.should be_associable
    end
  end
end