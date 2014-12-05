require 'spec_helper'

describe TableCopier do
  let(:copier) do
    TableCopier.new(
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

  context "stubbed db" do
    let(:user) { "some guy" }
    let(:account) { "some guy's account" }
    let(:source_dataset) { datasets(:table) }
    let(:destination_schema) { schemas(:default) }
    let(:destination_table_name) { "hello" }
    let(:destination_connection) { Object.new }
    let(:source_connection) { Object.new }
    let(:sample_count) { nil }
    let(:truncate) { false }
    let(:pipe_name) { 'import_handle' }

    before do
      stub(source_dataset).connect_as(user) { source_connection }
      stub(source_dataset).connect_with(account) { source_connection }
      stub(source_dataset.data_source).account_for_user! { account }

      stub(destination_schema).connect_as(user) { destination_connection }
      stub(destination_schema).connect_with(account) { destination_connection }
      stub(destination_connection).is_hawq? { false }
    end

    describe "#initialize_destination_table" do
      subject { copier.initialize_destination_table }

      context "when it doesn't exist yet" do
        before do
          stub(destination_connection).table_exists?(destination_table_name) { false }
          stub(source_connection).column_info(source_dataset.name, anything) do
            [
                {:attname => 'foo', :format_type => "integer"},
                {:attname => 'bar', :format_type => "character varying"},
                {:attname => 'baz', :format_type => "numeric"}
            ]
          end
          stub(source_connection).primary_key_columns(source_dataset.name) { primary_keys }
          stub(source_connection).distribution_key_columns(source_dataset.name) { distribution_keys }
        end

        let(:primary_keys) { [] }
        let(:distribution_keys) { [] }

        it "should create it with the correct columns" do
          mock(destination_connection).create_table(destination_table_name, %Q{"foo" integer, "bar" character varying, "baz" numeric}, 'DISTRIBUTED RANDOMLY')
          copier.initialize_destination_table
        end

        context "with a primary key" do
          let(:primary_keys) { %w(hi bye) }

          it "should add the primary key clause to the columns" do
            mock(destination_connection).create_table(destination_table_name, satisfy { |arg| arg.ends_with?(", PRIMARY KEY(\"hi\", \"bye\")") }, anything)
            subject
          end
        end

        context "with a distribution key" do
          let(:distribution_keys) { %w(whats up) }

          it "should distribute the new table correctly" do
            mock(destination_connection).create_table(destination_table_name, anything, %Q{DISTRIBUTED BY("whats", "up")})
            subject
          end
        end

        context "for a chorus view" do
          let(:source_dataset) { datasets(:chorus_view) }

          before do
            dont_allow(source_connection).distribution_key_columns
            dont_allow(source_connection).primary_key_columns
          end

          it "should distribute randomly with no primary key" do
            mock(destination_connection).create_table(destination_table_name, satisfy { |arg| !(arg =~ /primary key/i) }, 'DISTRIBUTED RANDOMLY')
            subject
          end
        end
      end

      context "when it exists" do
        before do
          stub(destination_connection).table_exists?(destination_table_name) { true }
        end

        it "should not create it" do
          dont_allow(destination_connection).create_table(destination_table_name, anything, anything)
          dont_allow(destination_connection).truncate_table(destination_table_name)
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

    describe "#run" do
      it "should insert the data into the destination table" do
        mock(source_connection).copy_table_data(%Q{"#{destination_schema.name}"."#{destination_table_name}"}, source_dataset.name, '', {
            :limit => sample_count,
            :check_id => pipe_name,
            :user => user
        })
        copier.run
      end
    end
  end

  describe "cancel" do
    let(:import) do
      imports(:one).tap { |imp| imp.update_attribute(:to_table, datasets(:table).name) }
    end

    it "cancels the CancelableQuery" do
      import.copier_class.should == TableCopier
      stub.proxy(CancelableQuery).new(nil, import.handle, import.user) { |query| mock(query).cancel }

      TableCopier.cancel(import)
    end
  end

  context "db integration", :greenplum_integration do
    let(:user) { GreenplumIntegration.real_account.owner }
    let(:database) { GreenplumIntegration.real_database }
    let(:source_dataset) { destination_schema.datasets.find_by_name('base_table1') }
    let(:destination_schema) { database.schemas.find_by_name('test_schema') }
    let(:sample_count) { nil }
    let(:truncate) { false }
    let(:pipe_name) { 'import_handle_2' }

    let(:source_conn) { source_dataset.connect_as(user) }
    let(:dest_conn) { destination_schema.connect_as(user) }

    subject { copier.start }

    context "when the destination table doesn't exist" do
      let(:destination_table_name) { "dont_exist" }

      after do
        destination_schema.connect_as(user).drop_table(destination_table_name)
      end

      it "should create the table and copy data in" do
        expect do
          subject
        end.to change { dest_conn.table_exists?(destination_table_name) }.to(true)

        source_columns = source_conn.column_info(source_dataset.name, '').map { |hash| hash.slice(:attname, :format_type) }
        dest_columns = dest_conn.column_info(destination_table_name, '').map { |hash| hash.slice(:attname, :format_type) }
        source_columns.should == dest_columns
      end

      context "when the destination is a HAWQ data source", :hawq_integration do
        let(:destination_schema) { destination_data_source.databases.first.schemas.first }
        let!(:destination_data_source) { HawqIntegration.real_data_source }

        let(:source_dataset) { GreenplumIntegration.real_database.datasets.first  }

        before do
          destination_data_source.refresh_databases
        end

        it "can create the destination table" do
          expect do
            copier.initialize_destination_table
          end.not_to raise_error
        end
      end
    end

    context "when the destination table exists" do
      before do
        conn.execute("SET search_path to #{destination_schema.name}")
        conn.create_table(destination_table_name, :as => "select * from #{source_dataset.schema.name}.base_table1 limit 0")
      end

      after do
        conn.drop_table(destination_table_name, :if_exists => true)
        conn.disconnect
      end

      let(:conn) do
        connection = destination_schema.connect_as(user)
        Sequel.connect(connection.db_url, connection.db_options)
      end
      let(:destination_table_name) { "temporary_for_copy" }

      context "when the source dataset is a chorus view" do
        let(:source_dataset) { datasets(:executable_chorus_view) }

        it "should work" do
          expect do
            subject
          end.to change { conn.fetch("SELECT * from #{destination_table_name}").all.length }
        end
      end
    end
  end
end
