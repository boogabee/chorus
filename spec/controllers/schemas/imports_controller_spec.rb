require 'spec_helper'

describe Schemas::ImportsController do
  describe '#create' do
    let(:source_dataset) { datasets(:oracle_table) }
    let(:schema) { schemas(:default) }
    let(:user) { schema.data_source.owner }

    before do
      any_instance_of(GreenplumConnection) do |connection|
        stub(connection).table_exists?(to_table) { table_exists }
      end
      log_in user
    end

    context 'when importing a dataset immediately' do
      context 'into a new destination dataset' do
        let(:table_exists) { false }
        let(:to_table) { "the_new_table" }
        let(:attributes) {
          HashWithIndifferentAccess.new(
            :to_table => to_table,
            :sample_count => "12",
            :schema_id => schema.to_param,
            :truncate => "false",
            :dataset_id => source_dataset.to_param,
            :new_table => 'true'
          )
        }

        it 'has the right response code' do
          post :create, attributes
          response.code.should == "201"
        end

        it 'creates a new import' do
          expect {
            post :create, attributes
          }.to change(SchemaImport, :count).by(1)
          import = SchemaImport.last
          import.schema.should == schema
          import.to_table.should == to_table
          import.source_dataset.should == source_dataset
          import.truncate.should == false
          import.user_id.should == user.id
          import.sample_count.should == 12
          import.new_table.should == true
        end
      end
    end
  end

  context 'in demo mode' do
    let(:source_dataset) { datasets(:oracle_table) }
    let(:schema) { schemas(:default) }
    let(:attributes) {
      HashWithIndifferentAccess.new(
          :schema_id => schema.to_param,
          :dataset_id => source_dataset.to_param
      )
    }

    it_behaves_like 'a protected demo mode controller', [:create] do
      let(:params) { attributes }
    end
  end

  context "integration", :greenplum_integration => true, :oracle_integration => true do
    let(:user) { users(:owner) }
    let(:source_table) { OracleIntegration.real_schema.datasets.find_by_name('ALL_COLUMN_TABLE') }
    let(:schema) { GpdbSchema.find_by_name('test_schema') }

    let(:params) do
      {
          :schema_id => schema.to_param,
          :dataset_id => source_table.to_param,
          :truncate => "false"
      }
    end

    before do
      clean_up_tables
      run_jobs_synchronously
      log_in user
    end

    after do
      clean_up_tables
    end

    it "can perform an import into a new table" do
      post :create, params.merge(:new_table => "true", :to_table => "some_new_table")
      response.code.should eq("201")

      results = GreenplumIntegration.exec_sql_line_with_results("select * from \"#{schema.name}\".some_new_table")

      results.first[:BIN_DOUBLE].to_f.should eq(2.3)
      results.first[:CHARACTER].should eq('c')
      results.first[:CHAR_BLOB].should eq('some long text and stuff')
      results.first[:DAY].to_date.should == Date.parse('2011-12-23')
    end

    it "can perform an import into an existing table" do
      create_existing_table
      populate_existing_table

      post :create, params.merge(:new_table => "false", :to_table => "existing_table")
      response.code.should eq("201")

      results = GreenplumIntegration.exec_sql_line_with_results("select * from \"#{schema.name}\".existing_table order by \"BIN_DOUBLE\"")
      results[1][:BIN_DOUBLE].to_f.should eq(2.4)
      results[1][:CHARACTER].should eq('d')
      results[1][:CHAR_BLOB].should eq('some other long text and other stuff')
      results[1][:DAY].to_date.should == Date.parse('2011-12-24')
    end


    def create_existing_table
      create_table_sql = <<-SQL
      CREATE TABLE "#{schema.name}".existing_table (
        "BIN_DOUBLE" double precision
      , "BIN_FLOAT" double precision
      , "CHARACTER" character(1)
      , "CHAR_BLOB" text
      , "DAY" timestamp without time zone
      , "DECIMAL_COL" numeric
      , "INTEGER_COL" numeric
      , "UNICODE_CHAR" character(1)
      , "UNICODE_CLOB" text
      , "NUMBER_COL" numeric
      , "UNICODE_VARCHAR" character varying
      , "ROW_ID" text
      , "TIMESTAMP_COL" timestamp without time zone
      , "UNIVERSAL_ROW_ID" text
      , "VARIABLE_CHARACTER" character varying
      , "VARIABLE_CHARACTER_2" character varying
      , "LONG_COLUMN" text
      );
      SQL

      GreenplumIntegration.execute_sql(create_table_sql)
      schema.refresh_datasets(GreenplumIntegration.real_account)
    end

    def populate_existing_table
      insert_values_sql = <<-SQL2
      INSERT INTO "#{schema.name}".existing_table VALUES (
        2.4,
        5.4,
        'd',
        'some other long text and other stuff',
        to_date('2011-12-24', 'YYYY-MM-DD'),
        123,
        43,
        'W',
        'long other thingy',
        433,
        'other stuff',
        NULL,
        TO_TIMESTAMP('10-SEP-0214:10:10.123001','DD-MON-RRHH24:MI:SS.FF'),
        NULL,
        'some other string',
        'another some other string so there shutup',
        'not actually very long content'
      );
      SQL2

      GreenplumIntegration.execute_sql(insert_values_sql)
    end

    def clean_up_tables
      GreenplumIntegration.execute_sql("DROP TABLE IF EXISTS #{schema.name}.some_new_table;")
      GreenplumIntegration.execute_sql("DROP TABLE IF EXISTS #{schema.name}.existing_table;")
    end
  end
end