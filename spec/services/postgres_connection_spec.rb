require 'spec_helper'

describe PostgresConnection, :postgres_integration do
  let(:data_source) { PostgresIntegration.real_data_source }
  let(:database_name) { PostgresIntegration.database_name }
  let(:db_url) { connection.db_url }
  let(:db_options) { connection.db_options }
  let(:account) { data_source.account_for_user!(users(:owner)) }
  let(:exception_class) { described_class.error_class }

  before do
    stub.proxy(Sequel).connect.with_any_args
  end

  let(:options) { {
      :database => database_name,
      :logger => Rails.logger
  } }

  let(:connection) { PostgresConnection.new(data_source, account, options) }

  context 'basic' do
    it_should_behave_like 'a data source connection' do
      let(:empty_set_sql) { 'SELECT 1 where false;' }
      let(:sql) { 'SELECT 1 AS col1' }
      let(:sql_with_parameter) { 'SELECT :param as col1' }
    end

    it_should_behave_like 'a postgres-like connection' do
      let(:integration_schema_name) { PostgresIntegration.schema_name }
    end
  end

  # describe 'prepare_and_execute_statement' do
  #   let(:sql) { 'SELECT 1 AS answer' }
  #   let(:execute_options) { {} }
  #   let(:expected) { [{'answer' => '1'}] }
  #
  #   subject { connection.prepare_and_execute_statement(sql, execute_options) }
  #
  #   it 'should return a SqlResult' do
  #     subject.should be_a(SqlResult)
  #     subject.hashes.should == expected
  #   end
  #
  #   it 'stores the statement through the cancelable_query' do
  #     cancelable_query = Object.new
  #     mock(cancelable_query).store_statement.with_any_args
  #     connection.prepare_and_execute_statement(sql, {}, cancelable_query)
  #   end
  #
  #   describe 'when the schema is set' do
  #     before do
  #       options.merge!(
  #           :schema => 'test_schema',
  #           :logger => Rails.logger
  #       )
  #     end
  #
  #     let(:sql) { 'SELECT * from table_in_public' }
  #
  #     it "doesn't search public by default" do
  #       expect { subject }.to raise_error(PostgresLikeConnection::QueryError, /"table_in_public" does not exist/)
  #     end
  #
  #     describe 'when including the public schema in the search path' do
  #       let(:execute_options) { {:include_public_schema_in_search_path => true} }
  #
  #       it 'finds the the table in the public schema' do
  #         expect {
  #           subject.should be_a(SqlResult)
  #         }.not_to raise_error
  #       end
  #
  #       context 'when the database does not have a public schema' do
  #         let(:database_name) { PostgresIntegration.database_name << '_wo_pub' }
  #         let(:sql) { 'SELECT 1' }
  #
  #         it 'does not raise an error' do
  #           expect {
  #             subject
  #           }.not_to raise_error
  #         end
  #       end
  #     end
  #   end
  #
  #   context 'when the query has no results' do
  #     let(:sql) { '' }
  #
  #     it 'should be empty' do
  #       subject.rows.should be_empty
  #     end
  #   end
  #
  #   context 'when there are multiple statements' do
  #     context 'with multiple results' do
  #       let(:sql) { 'SELECT 2 AS question; SELECT 1 AS answer' }
  #
  #       it 'should return the last results' do
  #         subject.should be_a(SqlResult)
  #         subject.hashes.should == expected
  #       end
  #     end
  #
  #     context "when some don't have results" do
  #       let(:sql) { 'create table surface_warnings (id INT PRIMARY KEY); drop table surface_warnings; SELECT 1 AS answer' }
  #
  #       it 'should return the last results' do
  #         subject.hashes.should == expected
  #       end
  #     end
  #   end
  #
  #   context 'with warnings enabled' do
  #     let(:sql) { 'create table surface_warnings (id INT PRIMARY KEY); drop table surface_warnings;create table surface_warnings (id INT PRIMARY KEY); drop table surface_warnings;' }
  #     let(:execute_options) { {:warnings => true} }
  #
  #     it 'surfaces all notices and warnings' do
  #       subject.warnings.length.should == 2
  #       subject.warnings.each do |warning|
  #         warning.should match /will create implicit index/
  #       end
  #     end
  #   end
  #
  #   context 'limiting queries' do
  #     let(:sql) { 'select 1 as hi limit 3; select * from test_schema.base_table1 limit 4' }
  #
  #     context 'when a limit is passed' do
  #       let(:execute_options) { {:limit => 1} }
  #
  #       it 'should limit the query' do
  #         subject.rows.length.should == 1
  #       end
  #
  #       it 'should optimize the query to only actually fetch the limited number of rows, not just fetch all and subselect' do
  #         stub.proxy(Sequel).connect(db_url, anything) do |connection|
  #           connection.synchronize do |jdbc_conn|
  #             mock.proxy(jdbc_conn).set_auto_commit(false)
  #             stub.proxy(jdbc_conn).prepare_statement do |statement|
  #               mock.proxy(statement).set_max_rows(1)
  #             end
  #             mock.proxy(jdbc_conn).commit
  #
  #             stub(connection).synchronize.with_no_args.yields(jdbc_conn)
  #           end
  #           connection
  #         end
  #
  #         subject
  #       end
  #     end
  #
  #     context 'when no limit is passed' do
  #       it 'should not limit the query' do
  #         subject.rows.length.should > 1
  #       end
  #
  #       it 'should not disable auto_commit' do
  #         stub.proxy(Sequel).connect(db_url, db_options.merge(:test => true)) do |connection|
  #           connection.synchronize(:default) do |jdbc_conn|
  #             dont_allow(jdbc_conn).set_auto_commit(false)
  #             stub(connection).synchronize.with_no_args.yields(jdbc_conn)
  #           end
  #           connection
  #         end
  #
  #         subject
  #       end
  #     end
  #   end
  #
  #   context 'when a query error occurs' do
  #     let(:sql) { 'select hi from non_existant_table_please' }
  #
  #     it 'should wrap it in a QueryError' do
  #       expect { subject }.to raise_error(PostgresLikeConnection::QueryError)
  #     end
  #   end
  #
  #   context 'when a database error occurs' do
  #     before do
  #       account.invalid_credentials!
  #     end
  #
  #     it 'should leave the error alone' do
  #       expect { subject }.to raise_error(DataSourceConnection::InvalidCredentials)
  #     end
  #   end
  #
  #   context 'when a timeout is specified' do
  #     let(:execute_options) { {:timeout => 0.1} }
  #     let(:sql) { 'SELECT pg_sleep(.2);' }
  #
  #     it 'should raise a timeout error' do
  #       expect { subject }.to raise_error(PostgresLikeConnection::QueryError, /timeout/)
  #     end
  #   end
  # end

  # describe 'process management' do
  #   let(:sql) { 'SELECT pg_sleep(300) /* kill_me */' }
  #   let(:runner_connection) { PostgresConnection.new(data_source, account, options) }
  #   let(:thread) do
  #     Thread.new do
  #       begin
  #         runner_connection.fetch sql
  #       rescue PostgresLikeConnection::DatabaseError
  #       end
  #     end
  #   end
  #
  #   after do
  #     connection.fetch "SELECT pg_terminate_backend(procpid) FROM (SELECT procpid from pg_stat_activity where current_query like '%kill_me%' and current_query not like '%procpid%') AS PROCPIDS"
  #     thread.kill
  #   end
  #
  #   it 'finds and kills executing queries that match the given sql' do
  #     thread
  #     timeout(10) do
  #       until connection.running?('kill_me') do
  #         sleep 0.1
  #       end
  #     end
  #     connection.kill 'kill_me'
  #     connection.running?('kill_me').should be_false
  #   end
  # end

  describe 'DataSourceMethods' do
    let(:database_name) { 'postgres' }

    describe '#version' do
      let(:expected) { db.fetch('select version()').first[:version].match(/PostgreSQL ([\d\.]*)/)[1] }
      let(:subject) { connection.version }

      it_should_behave_like 'a well-behaved database query'
    end
  end

  describe 'SchemaMethods' do
    let(:connection) { PostgresConnection.new(data_source, account, options.merge(:schema => schema_name)) }
    let(:schema_name) { PostgresIntegration.schema_name }

    describe 'datasets' do
      let(:datasets_sql) do
        (<<-SQL).strip_heredoc
          SELECT c.relkind as type, c.relname as name, c.relhassubclass as master_table
            FROM pg_catalog.pg_class c
              JOIN pg_catalog.pg_namespace n ON ( n.oid = c.relnamespace AND n.nspname = 'test_schema')
            WHERE c.relkind in ('r', 'v')
          ORDER BY lower(replace(relname,'_', '')) ASC
        SQL
      end

      let(:expected) { db.fetch(datasets_sql, :schema => schema_name).all }
      let(:subject) { connection.datasets }

      it_should_behave_like 'a well-behaved database query'

      context 'when the user does not have permission to the schema' do
        let(:subject) { connection.datasets }
        let(:db) { Sequel.connect(db_url, db_options) }
        let(:restricted_user) { 'user_with_no_access' }
        let(:restricted_password) { 'secret' }

        let(:connection) do
          PostgresConnection.new(data_source, account, options.merge(:schema => schema_name, :account => account))
        end

        before do
          db.execute("CREATE USER #{restricted_user} WITH PASSWORD '#{restricted_password}';") rescue nil
          db.execute("GRANT CONNECT ON DATABASE \"#{database_name}\" TO #{restricted_user};")
          db.execute("REVOKE ALL ON SCHEMA #{schema_name} FROM #{restricted_user};")
          account.db_username = restricted_user
          account.db_password = restricted_password
        end

        after do
          db.execute("REVOKE CONNECT ON DATABASE \"#{database_name}\" FROM #{restricted_user};") rescue nil
          db.execute("DROP USER #{restricted_user};") rescue nil
          db.disconnect
        end

        it 'should raise a SqlPermissionDenied' do
          expect { subject }.to raise_error(PostgresLikeConnection::SqlPermissionDenied)
        end
      end

      context 'when a limit is passed' do
        let(:datasets_sql) do
          <<-SQL
            SELECT c.relkind as type, c.relname as name, c.relhassubclass as master_table
              FROM pg_catalog.pg_class c
                JOIN pg_catalog.pg_namespace n ON ( n.oid = c.relnamespace AND n.nspname = 'test_schema')
              WHERE c.relkind in ('r', 'v')
            ORDER BY lower(replace(relname,'_', '')) ASC
            LIMIT 2
          SQL
        end
        let(:expected) { db.fetch(datasets_sql, :schema => schema_name).all }
        let(:subject) { connection.datasets(:limit => 2) }

        it_should_behave_like 'a well-behaved database query'
      end

      context 'when a name filter is passed' do
        let(:subject) { connection.datasets(:name_filter => name_filter) }

        context 'and the filter does not contain LIKE wildcards' do
          let(:name_filter) {'cANdy'}
          let(:expected) { db.fetch(datasets_sql, :schema => schema_name).all }
          let(:datasets_sql) do
            <<-SQL
              SELECT c.relkind as type, c.relname as name, c.relhassubclass as master_table
                FROM pg_catalog.pg_class c
                  JOIN pg_catalog.pg_namespace n ON ( n.oid = c.relnamespace AND n.nspname = 'test_schema')
                WHERE c.relkind in ('r', 'v')
                AND c.relname ILIKE '%candy%'
              ORDER BY lower(replace(relname,'_', '')) ASC
            SQL
          end

          it_should_behave_like 'a well-behaved database query'
        end

        context 'and the filter contains LIKE wildcards' do
          let(:name_filter) {'_c'}

          it "only returns which contain '_c' in their names (and it does not return 2candy)" do
            subject.length.should > 0
            subject.each { |dataset| dataset[:name].should include '_c' }
          end
        end
      end

      context 'when only showing tables' do
        let(:datasets_sql) do
          <<-SQL
            SELECT c.relkind as type, c.relname as name, c.relhassubclass as master_table
              FROM pg_catalog.pg_class c
                JOIN pg_catalog.pg_namespace n ON ( n.oid = c.relnamespace AND n.nspname = 'test_schema')
              WHERE c.relkind = 'r'
            ORDER BY lower(replace(relname,'_', '')) ASC
          SQL
        end
        let(:expected) { db.fetch(datasets_sql, :schema => schema_name).all }
        let(:subject) { connection.datasets(:tables_only => true) }

        it_should_behave_like 'a well-behaved database query'

        it 'does not include external tables' do
          connection.datasets(:tables_only => true).select {|dataset| dataset[:name] =~ /external/}.should be_empty
        end
      end

      context 'when multiple options are passed' do
        let(:datasets_sql) do
          <<-SQL
            SELECT c.relkind as type, c.relname as name, c.relhassubclass as master_table
              FROM pg_catalog.pg_class c
                JOIN pg_catalog.pg_namespace n ON ( n.oid = c.relnamespace AND n.nspname = 'test_schema')
              WHERE c.relkind in ('r', 'v')
              AND c.relname ILIKE '%candy%'
            ORDER BY lower(replace(relname,'_', '')) ASC
            LIMIT 2
          SQL
        end
        let(:expected) { db.fetch(datasets_sql, :schema => schema_name).all }
        let(:subject) { connection.datasets(:name_filter => 'caNDy', :limit => 2) }

        it_should_behave_like 'a well-behaved database query'
      end
    end

    describe 'datasets_count' do
      let(:datasets_sql) do
        <<-SQL
          SELECT count(c.relname)
            FROM pg_catalog.pg_class c
              JOIN pg_catalog.pg_namespace n ON ( n.oid = c.relnamespace AND n.nspname = 'test_schema')
            WHERE c.relkind in ('r', 'v')
        SQL
      end
      let(:expected) { db.fetch(datasets_sql, :schema => schema_name).single_value }
      let(:subject) { connection.datasets_count }

      it_should_behave_like 'a well-behaved database query'

      context "when the user doesn't have permission to the schema" do
        let(:subject) { connection.datasets_count }
        let(:db) { Sequel.connect(db_url, db_options) }
        let(:restricted_user) { 'user_with_no_access' }
        let(:restricted_password) { 'secret' }

        let(:connection) do
          PostgresConnection.new(data_source, account, options.merge(:schema => schema_name, :account => account))
        end

        before do
          db.execute("CREATE USER #{restricted_user} WITH PASSWORD '#{restricted_password}';") rescue nil
          db.execute("GRANT CONNECT ON DATABASE \"#{database_name}\" TO #{restricted_user};")
          db.execute("REVOKE ALL ON SCHEMA #{schema_name} FROM #{restricted_user};")
          account.db_username = restricted_user
          account.db_password = restricted_password
        end

        after do
          db.execute("REVOKE CONNECT ON DATABASE \"#{database_name}\" FROM #{restricted_user};") rescue nil
          db.execute("DROP USER #{restricted_user};") rescue nil
          db.disconnect
        end

        it 'raises SqlPermissionDenied' do
          expect { subject }.to raise_error(PostgresLikeConnection::SqlPermissionDenied)
        end
      end

      context 'when a name filter is passed' do
        let(:datasets_sql) do
          <<-SQL
            SELECT count(c.relname)
              FROM pg_catalog.pg_class c
                JOIN pg_catalog.pg_namespace n ON ( n.oid = c.relnamespace AND n.nspname = 'test_schema')
              WHERE c.relkind in ('r', 'v')
              AND c.relname ILIKE '%candy%'
          SQL
        end
        let(:expected) { db.fetch(datasets_sql, :schema => schema_name).single_value }
        let(:subject) { connection.datasets_count(:name_filter => 'cANdy') }

        it_should_behave_like 'a well-behaved database query'
      end
    end

    describe 'metadata_for_dataset' do
      context 'a base table' do
        let(:dataset_name) { 'base_table1' }

        it 'returns statistics for a dataset' do
          row = connection.metadata_for_dataset(dataset_name)
          row[:name].should == 'base_table1'
          row[:description].should == 'comment on base_table1'
          row[:column_count].should == 5
          row[:last_analyzed].should_not be_nil
          row[:row_count].should be 9
          row[:definition].should be_nil
          row[:table_type].should == 'BASE_TABLE'
        end
      end

      context 'a view' do
        let(:dataset_name) { 'view1' }

        it 'returns statistics for a dataset' do
          row = connection.metadata_for_dataset(dataset_name)
          row[:name].should == 'view1'
          row[:description].should == 'comment on view1'
          row[:column_count].should == 5
          row[:definition].should_not be_nil
          row[:table_type].should == 'VIEW'
        end
      end

      context 'when the table does not exist' do
        let(:dataset_name) { 'something_that_doesnt_exist?' }

        it 'returns nil' do
          connection.metadata_for_dataset(dataset_name).should be_nil
        end
      end
    end

    describe '#create_table' do
      let(:destination_table_name) { 'a_new_db_table' }
      let!(:db) { Sequel.connect(db_url, db_options) }

      after do
        db.drop_table(Sequel.qualify(schema_name, 'a_new_db_table'), :if_exists => true)
        db.disconnect
      end

      let(:table_definition) { 'id integer PRIMARY KEY, column1 integer, column2 integer' }
      let(:distribution_clause) { nil }
      let(:subject) { connection.create_table(destination_table_name, table_definition, distribution_clause) }
      let(:expected) { true }

      it_should_behave_like 'a well-behaved database query'

      it 'creates a table' do
        expect {
          subject
        }.to change { Sequel.connect(db_url, db_options).tables(:schema => schema_name) }
      end

      context 'when a table with that name already exists' do
        let(:destination_table_name) { 'candy' }
        it 'raises an error' do
          expect {
            subject
          }.to raise_error(PostgresLikeConnection::DatabaseError)
        end
      end

      it 'ignores the distribution clause passed' do
        expect {
          connection.create_table(destination_table_name, table_definition, 'DISTRIBUTED RANDOMLY')
        }.to_not raise_error
      end
    end

    describe '#distribution_key_columns' do
      it 'returns empty array' do
        connection.distribution_key_columns('base_table1').should == []
      end
    end
  end
end
