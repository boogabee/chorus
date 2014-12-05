require 'spec_helper'

describe MultiPgTableCopier, :postgres_integration do

  let(:user) { PostgresIntegration.real_account.owner }
  let(:destination_database) { PostgresIntegration.real_database_priv }
  let(:destination_schema) { destination_database.schemas.find_by_name('public') }
  let(:source_database) { PostgresIntegration.real_database }
  let(:source_dataset) { source_database.find_dataset_in_schema('base_table1', 'test_schema') }

  let(:destination_table_name) { 'copied_in' }
  let(:sample_count) { nil }
  let(:truncate) { false }

  let(:copier) do
    described_class.new({
        :source => source_dataset,
        :destination_schema => destination_schema,
        :destination_table_name => destination_table_name,
        :user => user,
        :sample_count => sample_count,
        :truncate => truncate,
        :pipe_name => 'pipe_id'
    })
  end

  let(:source_db_url) { PostgresIntegration.db_url(source_database.name) }
  let(:dest_db_url) { PostgresIntegration.db_url(destination_database.name) }
  let(:options) do
    {
        :user => PostgresIntegration.username,
        :password => PostgresIntegration.password,
        :logger => Rails.logger
    }
  end

  def with_connection(url, &block)
    Sequel.connect(url, options, &block)
  end

  context '#start' do
    let(:qualified_dest_name) { "#{destination_schema.name}.#{destination_table_name}" }

    before do
      with_connection(dest_db_url) do |conn|
        conn.run("drop table if exists #{qualified_dest_name};")
      end
    end

    it 'copies it in' do
      copier.start
      source_row_count = with_connection(source_db_url) { |c| c.fetch('select count(*) from test_schema.base_table1;').single_value }
      source_row_count.should > 5
      dest_row_count = with_connection(dest_db_url) { |c| c.fetch("select count(*) from #{qualified_dest_name}").single_value }
      dest_row_count.should == source_row_count
    end

    it 'includes pipe_name in the query for cancel-ability' do
      mock.proxy(Java::OrgPostgresqlCopy::PGCopyInputStream).new(anything, %r|/\*pipe_id\*/|)
      copier.start
    end

    context 'when limiting the number of rows imported' do
      let(:sample_count) { 2 }

      it 'copies only the reduced row count' do
        copier.start
        source_row_count = with_connection(source_db_url) { |c| c.fetch('select count(*) from test_schema.base_table1;').single_value }
        source_row_count.should > 2
        dest_row_count = with_connection(dest_db_url) { |c| c.fetch("select count(*) from #{qualified_dest_name}").single_value }
        dest_row_count.should == 2
      end
    end

    context 'into an existing table' do
      context 'with the same columns in a different order' do
        before do
          with_connection(dest_db_url) do |conn|
            conn.run("drop table if exists #{qualified_dest_name};")
            conn.run(<<-SQL)
              CREATE TABLE #{qualified_dest_name}
                (time_value timestamp, id integer PRIMARY KEY, column1 integer, column2 integer, category text);
            SQL
          end
        end

        it 'copies it in' do
          copier.start
          source_check = with_connection(source_db_url) { |c| c.fetch('select category from test_schema.base_table1 where id = 0;').single_value }
          dest_check = with_connection(dest_db_url) { |c| c.fetch("select category from #{qualified_dest_name} where id = 0;").single_value }
          dest_check.should == source_check
        end
      end
    end
  end

  context '#cancel' do
    let(:user) { import.user }
    let(:source_connection) { Object.new }
    let(:import) { imports(:now) }
    let(:copier) {}

    before do
      stub(import.source_dataset).connect_as(user) { source_connection }
      stub(import).handle { 'pipe_id' }
    end

    it 'kills the source connection' do
      mock(source_connection).kill('pipe_id')

      described_class.cancel(import)
    end
  end
end
