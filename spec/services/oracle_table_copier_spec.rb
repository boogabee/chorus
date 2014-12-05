require 'spec_helper'

describe OracleTableCopier do
  let(:user) { "some guy" }
  let(:account) { "some guy's account" }
  let(:source_dataset) { datasets(:oracle_table) }
  let(:destination_schema) { schemas(:default) }
  let(:destination_table_name) { "hello" }
  let(:destination_connection) { Object.new }
  let(:source_connection) { Object.new }
  let(:sample_count) { nil }
  let(:truncate) { false }
  let(:pipe_name) { 'the_pipe_name' }
  let(:destination_exists) { false }

  let(:copier) do
    OracleTableCopier.new(
        {
            :source => source_dataset,
            :destination_schema => destination_schema,
            :destination_table_name => destination_table_name,
            :user => user,
            :sample_count => sample_count,
            :truncate => truncate,
            :pipe_name => pipe_name
        }
    )
  end

  context 'with stubbed databases' do
    before do
      stub(source_dataset).connect_as(user) { source_connection }
      stub(source_dataset).connect_with(account) { source_connection }
      stub(source_dataset.data_source).account_for_user! { account }

      stub(destination_schema).connect_as(user) { destination_connection }
      stub(destination_schema).connect_with(account) { destination_connection }

      stub(destination_connection).table_exists?(destination_table_name) { destination_exists }
      stub(destination_connection).is_hawq? { false }
      stub(source_connection).column_info(source_dataset.name, anything) do
        [
            {:attname => "BIN_DOUBLE", :format_type => "BINARY_DOUBLE"},
            {:attname => "BIN_FLOAT", :format_type => "BINARY_FLOAT"},
            {:attname => "CHARACTER", :format_type => "CHAR"},
            {:attname => "CHAR_BLOB", :format_type => "CLOB"},
            {:attname => "DAY", :format_type => "DATE"},
            {:attname => "DECIMAL_COL", :format_type => "DECIMAL"},
            {:attname => "INTEGER_COL", :format_type => "INT"},
            {:attname => "LONG_COL", :format_type => "LONG"},
            {:attname => "NUMBER_COL", :format_type => "NUMBER"},
            {:attname => "ROW_ID", :format_type => "ROWID"},
            {:attname => "TIMESTAMP_COL", :format_type => "TIMESTAMP(6)"},
            {:attname => "UNICODE_CHAR", :format_type => "NCHAR"},
            {:attname => "UNICODE_CLOB", :format_type => "NCLOB"},
            {:attname => "UNICODE_VARCHAR", :format_type => "NVARCHAR2"},
            {:attname => "UNIVERSAL_ROW_ID", :format_type => "UROWID"},
            {:attname => "VARIABLE_CHARACTER", :format_type => "VARCHAR"},
            {:attname => "VARIABLE_CHARACTER_2", :format_type => "VARCHAR2"}
        ]
      end
      stub(source_connection).primary_key_columns(source_dataset.name) { primary_keys }
    end

    describe "initialization" do
      describe "initialize_destination_table" do
        subject { copier.initialize_destination_table }

        context "when it doesn't exist yet" do
          let(:destination_exists) { false }
          let(:primary_keys) { [] }

          it "creates it with the correct columns" do
            columns = [
                %Q{"BIN_DOUBLE" double precision},
                %Q{"BIN_FLOAT" double precision},
                %Q{"CHARACTER" character(1)},
                %Q{"CHAR_BLOB" text},
                %Q{"DAY" timestamp without time zone},
                %Q{"DECIMAL_COL" double precision},
                %Q{"INTEGER_COL" numeric},
                %Q{"LONG_COL" text},
                %Q{"NUMBER_COL" numeric},
                %Q{"ROW_ID" text},
                %Q{"TIMESTAMP_COL" timestamp without time zone},
                %Q{"UNICODE_CHAR" character(1)},
                %Q{"UNICODE_CLOB" text},
                %Q{"UNICODE_VARCHAR" character varying},
                %Q{"UNIVERSAL_ROW_ID" text},
                %Q{"VARIABLE_CHARACTER" character varying},
                %Q{"VARIABLE_CHARACTER_2" character varying},
            ]
            mock(destination_connection).create_table(destination_table_name, columns.join(', '), 'DISTRIBUTED RANDOMLY')
            copier.initialize_destination_table
          end

          context "with a primary key" do
            let(:primary_keys) { %w(hi bye) }

            it "should add the primary key clause to the columns and distribute correctly" do
              mock(destination_connection).create_table(destination_table_name, satisfy { |arg| arg.ends_with?(", PRIMARY KEY(\"hi\", \"bye\")") }, %Q{DISTRIBUTED BY("hi", "bye")})
              subject
            end
          end
        end

        context "when it exists" do
          let(:destination_exists) { true }

          it "should not create it" do
            dont_allow(destination_connection).create_table.with_any_args
            dont_allow(destination_connection).truncate_table.with_any_args
            subject
          end

          context "when it should be truncated" do
            let(:truncate) { true }
            it "should truncate" do
              mock(destination_connection).truncate_table(destination_table_name)
              subject
            end
          end
        end
      end
    end
  end

  describe "cancel" do
    let(:import) do
      imports(:oracle).tap { |imp| imp.update_attribute(:to_table, datasets(:table).name) }
    end

    it "cancels the CancelableQuery" do
      stub(import.source_dataset.data_source).connect_as(import.user) { source_connection }
      mock(CancelableQuery).new(source_connection, import.handle, import.user) { |query| mock(query).cancel }
      mock(OracleTableCopier).kill_session.with_any_args

      OracleTableCopier.cancel(import)
    end
  end

  context "db integration", :oracle_integration, :greenplum_integration do
    let(:user) { OracleIntegration.real_account.owner }
    let(:destination_schema) { GreenplumIntegration.real_database.schemas.find_by_name('test_schema') }
    let(:source_dataset) { OracleIntegration.real_schema.datasets.find_by_name('NEWTABLE') }
    let(:sample_count) { 5 }
    let(:truncate) { false }

    let(:source_conn) { source_dataset.connect_as(user) }
    let(:dest_conn) { destination_schema.connect_as(user) }

    subject { copier.start }

    context "when the destination table doesn't exist" do
      let(:destination_table_name) { "dont_exist" }

      after do
        destination_schema.connect_as(user).drop_table(destination_table_name)
      end

      it "should create the table and copy data in" do
        mock.proxy(SqlStreamer).new(anything, anything, anything, is_a(CancelableQuery))
        expect do
          subject
        end.to change { dest_conn.table_exists?(destination_table_name) }.to(true)

        source_column_types = source_conn.column_info(source_dataset.name, '').map { |hash| OracleDataTypes.greenplum_type_for(hash[:format_type]) }
        source_column_names = source_conn.column_info(source_dataset.name, '').map { |hash| hash[:attname] }
        dest_column_types = dest_conn.column_info(destination_table_name, '').map { |hash| hash[:format_type] }
        dest_column_names = dest_conn.column_info(destination_table_name, '').map { |hash| hash[:attname] }
        source_column_types.should == dest_column_types
        source_column_names.should == dest_column_names
        dest_conn.fetch("select * from #{destination_table_name}").count.should == sample_count
      end
    end
  end
end