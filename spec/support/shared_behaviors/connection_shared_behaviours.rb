shared_examples "a well-behaved database query" do
  let(:db) { Sequel.connect(db_url, db_options) }

  it "returns the expected result and manages its connection" do
    connection.should_not be_connected
    if defined? use_match_matcher
      subject.should =~ expected
    else
      subject.should == expected
    end
    connection.should_not be_connected
    db.disconnect
  end

  it "masks sequel errors" do
    stub(Sequel).connect(anything, anything) do
      raise Sequel::DatabaseError
    end

    expect {
      subject
    }.to raise_error(DataSourceConnection::Error)
  end
end

shared_examples "a data source connection" do
  describe "connect!" do
    context "when a logger is not provided" do
      before do
        options.delete :logger
        db_options.delete :logger
        mock.proxy(Sequel).connect(db_url, db_options.merge(:test => true))
      end

      context "with valid credentials" do
        it "connects successfully passing no logging options" do
          connection.connect!
          connection.should be_connected
        end
      end
    end

    context "when a logger is provided" do
      let(:logger) do
        log = Object.new
        stub(log).debug
        log
      end

      let(:options) {
        {
          :database => database_name,
          :logger => logger
        }
      }

      before do
        mock.proxy(Sequel).connect(db_url, hash_including(:test => true, :sql_log_level => :debug, :logger => logger))
      end

      context "with valid credentials" do
        it "connects successfully passing the proper logging options" do
          connection.connect!
          connection.should be_connected
        end
      end
    end

    context "when credentials are valid" do
      it "does not set invalid credentials on the account" do
        connection.connect!
        account.invalid_credentials?.should be_false
      end
    end

    context "when credentials are invalid" do
      before do
        account.db_username = 'wrong!'
        account.db_password = 'wrong!'
      end

      it "sets invalid_credentials on the account" do
        expect { connection.connect! }.to raise_error(DataSourceConnection::InvalidCredentials) do |exception|
          exception.subject.should == data_source
        end
        account.invalid_credentials?.should be_true
      end

      context "when account is already flagged as invalid" do
        before do
          account.invalid_credentials!
        end

        it "does not attempt to connect, but still throws an INVALID_PASSWORD error" do
          dont_allow(Sequel).connect
          expect { connection.connect! }.to raise_error(DataSourceConnection::InvalidCredentials) do |exception|
            exception.subject.should == data_source
          end
        end
      end

      context "when connection fails for some reason unrelated to invalid credentials" do
        before do
          data_source.port = '8675309'
        end

        it "does not set invalid credentials on the account" do
          expect { connection.connect! }.to raise_error(exception_class)
          account.invalid_credentials?.should be_false
        end
      end
    end

    it "has a default login timeout as specified in chorus config" do
      stub(ChorusConfig.instance).database_login_timeout { 12 }
      mock(Sequel).connect(db_url, hash_including(:login_timeout => 12))
      connection.connect!
    end
  end

  describe "disconnect" do
    before do
      mock_conn = Object.new

      mock(Sequel).connect(anything, anything) { mock_conn }
      mock(mock_conn).disconnect
      connection.connect!
    end

    it "disconnects Sequel connection" do
      connection.should be_connected
      connection.disconnect
      connection.should_not be_connected
    end
  end

  describe "with_connection" do
    before do
      mock.proxy(Sequel).connect(db_url, satisfy { |options| options[:test] })
    end

    context "with valid credentials" do
      it "connects for the duration of the given block" do
        expect {
          connection.with_connection do
            connection.should be_connected
            throw :ran_block
          end
        }.to throw_symbol :ran_block
        connection.should_not be_connected
      end

      it "can be nested" do
        connection.with_connection do
          connection.with_connection do
            connection.should be_connected
          end
        end
        connection.should_not be_connected
      end
    end
  end

  describe "fetch" do
    let(:parameters) { {} }
    let(:subject) { connection.fetch(sql) }
    let(:expected) { [{:col1 => 1}] }

    it_should_behave_like "a well-behaved database query"

    context "with SQL parameters" do
      let(:sql) { sql_with_parameter }
      let(:parameters) { {:param => 3} }

      it "succeeds" do
        connection.fetch(sql, parameters).should == [{:col1 => 3}]
      end
    end
  end

  describe "fetch_value" do
    let(:subject) { connection.fetch_value(sql) }
    let(:expected) { 1 }

    it_should_behave_like "a well-behaved database query"

    it "returns nil for an empty set" do
      connection.fetch_value(empty_set_sql).should == nil
    end
  end

  describe "error_type" do
    context "when an Error is created with an error_type" do
      let(:error) { exception_class.new(:ERROR) }
      it "returns the given error_type" do
        error.error_type.should == :ERROR
      end
    end
  end
end

shared_examples 'a postgres-like connection' do
  describe 'execute' do
    let(:sql) { "SET search_path TO 'public'" }
    let(:parameters) { {} }
    let(:subject) { connection.execute(sql) }
    let(:expected) { true }

    it_should_behave_like 'a well-behaved database query'
  end

  describe 'set_timeout' do
    let(:statement_connection) { Object.new }
    let(:statement) { Object.new }

    before do
      stub(statement).connection { statement_connection }
      sequel_connection = connection.connect!
      stub(sequel_connection).statement(statement_connection) do |conn, block|
        block.call statement
      end
    end

    it 'sets the statement_timeout' do
      mock(statement).execute('SET statement_timeout TO 123000')
      connection.set_timeout(123, statement)
    end
  end

  describe 'DataSourceMethods' do
    let(:database_name) { 'postgres' }

    describe 'databases' do
      let(:database_list_sql) do
        <<-SQL
          SELECT
            datname
          FROM
            pg_database
          WHERE
            datallowconn IS TRUE AND datname NOT IN ('postgres', 'template1')
            ORDER BY lower(datname) ASC
        SQL
      end

      let(:expected) { db.fetch(database_list_sql).all.collect { |row| row[:datname] } }
      let(:subject) { connection.databases }

      it_should_behave_like 'a well-behaved database query'
    end

    describe 'create_database' do
      let(:new_database_name) { 'foobarbaz' }
      let(:subject) { connection.create_database('foobarbaz') }
      let(:expected) { true }
      let!(:db) { Sequel.connect(db_url, db_options) }

      after do
        db.execute("drop database if exists #{new_database_name}")
        db.disconnect
      end

      it_should_behave_like 'a well-behaved database query'

      it 'adds a database' do
        expect {
          connection.create_database(new_database_name)
        }.to change { connection.databases }
      end
    end
  end

  describe 'DatabaseMethods' do
    describe 'schemas' do
      let(:schema_list_sql) do
        <<-SQL
      SELECT
        schemas.nspname as schema_name
      FROM
        pg_namespace schemas
      WHERE
        schemas.nspname NOT LIKE 'pg_%'
        AND schemas.nspname NOT IN ('information_schema', 'gp_toolkit', 'gpperfmon')
      ORDER BY lower(schemas.nspname)
        SQL
      end
      let(:expected) { db.fetch(schema_list_sql).all.collect { |row| row[:schema_name] } }
      let(:subject) { connection.schemas }

      it_should_behave_like 'a well-behaved database query'
    end

    describe 'schema_exists?' do
      let(:schema_name) { integration_schema_name }
      let(:subject) { connection.schema_exists?(schema_name) }
      let(:expected) { true }

      it_should_behave_like 'a well-behaved database query'

      context 'when the schema does not exist' do
        let(:schema_name) { 'does_not_exist' }

        it 'returns false' do
          connection.schema_exists?(schema_name).should be_false
        end
      end
    end

    describe 'create_schema' do
      let(:new_schema_name) { 'foobarbaz' }
      let(:subject) { connection.create_schema('foobarbaz') }
      let(:expected) { true }
      let!(:db) { Sequel.connect(db_url, db_options) }

      after do
        db.drop_schema(new_schema_name, :if_exists => true)
        db.disconnect
      end

      it_should_behave_like 'a well-behaved database query'

      it 'adds a schema' do
        expect {
          connection.create_schema('foobarbaz')
        }.to change { connection.schemas }
      end
    end

    describe 'drop_schema' do
      context 'if the schema exists' do
        let(:schema_to_drop) { 'hopefully_unused_schema' }
        let(:subject) { connection.drop_schema(schema_to_drop) }
        let(:expected) { true }
        let!(:db) { Sequel.connect(db_url, db_options) }

        before do
          db.create_schema(schema_to_drop)
        end

        after do
          db.drop_schema(schema_to_drop, :if_exists => true)
          db.disconnect
        end

        it_should_behave_like 'a well-behaved database query'

        it 'drops it' do
          connection.schema_exists?(schema_to_drop).should be_true
          connection.drop_schema(schema_to_drop)
          connection.schema_exists?(schema_to_drop).should be_false
        end
      end

      context 'if the schema does not exist' do
        let(:schema_to_drop) { 'never_existed' }

        it 'doesnt raise an error' do
          expect {
            connection.drop_schema(schema_to_drop)
          }.to_not raise_error
        end
      end
    end
  end

  describe 'SchemaMethods' do
    let(:connection) { PostgresConnection.new(data_source, account, options.merge(:schema => schema_name)) }
    let(:schema_name) { PostgresIntegration.schema_name }

    describe 'functions' do
      let(:schema_functions_sql) do
        <<-SQL
          SELECT t1.oid, t1.proname, t1.lanname, t1.rettype, t1.proargnames, (SELECT t2.typname ORDER BY inputtypeid) AS argtypes, t1.prosrc, d.description
            FROM ( SELECT p.oid,p.proname,
               CASE WHEN p.proargtypes='' THEN NULL
                   ELSE unnest(p.proargtypes)
                   END as inputtype,
               now() AS inputtypeid, p.proargnames, p.prosrc, l.lanname, t.typname AS rettype
             FROM pg_proc p, pg_namespace n, pg_type t, pg_language l
             WHERE p.pronamespace=n.oid
               AND p.prolang=l.oid
               AND p.prorettype = t.oid
               AND n.nspname= '#{schema_name}') AS t1
          LEFT JOIN pg_type AS t2
          ON t1.inputtype=t2.oid
          LEFT JOIN pg_description AS d ON t1.oid=d.objoid
          ORDER BY t1.oid;
        SQL
      end
      let(:expected) { db.fetch(schema_functions_sql).all }
      let(:subject) { connection.functions }

      it_should_behave_like 'a well-behaved database query'
    end

    describe 'disk_space_used' do
      let(:disk_space_sql) do
        <<-SQL
          SELECT sum(pg_total_relation_size(pg_catalog.pg_class.oid))::bigint AS size
          FROM   pg_catalog.pg_class
          LEFT JOIN pg_catalog.pg_namespace ON relnamespace = pg_catalog.pg_namespace.oid
          WHERE  pg_catalog.pg_namespace.nspname = '#{schema_name}'
        SQL
      end
      let(:schema_name) { 'test_schema3' }
      let(:expected) { db.fetch(disk_space_sql).single_value }
      let(:subject) { connection.disk_space_used }

      it_should_behave_like 'a well-behaved database query'
    end

    describe '#create_view' do
      let!(:db) { Sequel.connect(db_url, db_options) }

      after do
        db.drop_view(Sequel.qualify(schema_name, 'a_new_db_view')) if db.views(:schema => schema_name).map(&:to_s).include? 'a_new_db_view'
        db.disconnect
      end

      let(:subject) { connection.create_view('a_new_db_view', 'select 1;') }
      let(:expected) { true }

      it_should_behave_like 'a well-behaved database query'

      it 'creates a view' do
        expect {
          connection.create_view('a_new_db_view', 'select 1;')
        }.to change { db.views(:schema => schema_name) }
      end

      context 'when a view with that name already exists' do
        it 'raises an error' do
          expect {
            connection.create_view('view1', 'select 1;')
          }.to raise_error(PostgresLikeConnection::DatabaseError)
        end
      end
    end

    describe 'table_exists?' do
      let(:subject) { connection.table_exists?(table_name) }
      let(:expected) { true }

      context 'when the table exists' do
        let(:table_name) { 'different_names_table' }

        it_should_behave_like 'a well-behaved database query'

        context 'when the table has weird chars in the name' do
          let(:table_name) { %Q(7_`~!@#\$%^&*()+=[]{}|\\;:',<.>/?) }

          it_should_behave_like 'a well-behaved database query' #regression
        end
      end

      context "when the table doesn't exist" do
        let(:table_name) { 'please_dont_exist' }
        let(:expected) { false }

        it_should_behave_like 'a well-behaved database query'
      end

      context 'when the table name given is nil' do
        let(:table_name) { nil }
        let(:expected) { false }

        it_should_behave_like 'a well-behaved database query'
      end
    end

    describe 'view_exists?' do
      let(:subject) { connection.view_exists?(view_name) }
      context 'when the view exists' do
        let(:expected) { true }
        let(:view_name) { 'view1' }

        it_behaves_like 'a well-behaved database query'
      end

      context "when the view doesn't exist" do
        let(:view_name) { 'please_dont_exist' }
        let(:expected) { false }

        it_behaves_like 'a well-behaved database query'
      end

      context 'when the view name given is nil' do
        let(:view_name) { nil }
        let(:expected) { false }

        it_behaves_like 'a well-behaved database query'
      end
    end

    describe 'analyze_table' do
      context 'when the table exists' do
        let(:table_name) { 'table_to_analyze' }

        before do
          stub.proxy(Sequel).connect do |connection|
            stub(connection).execute(anything)
            mock(connection).execute(%Q{ANALYZE "#{schema_name}"."#{table_name}"})
          end
        end

        it 'analyzes the table' do
          connection.analyze_table(table_name)
        end
      end

      context 'when the table does not exist' do
        let(:table_name) { 'this_table_does_not_exist' }

        it 'raises an error' do
          expect do
            connection.analyze_table(table_name)
          end.to raise_error(PostgresLikeConnection::DatabaseError)
        end
      end
    end

    describe 'drop_table' do
      context 'if the table exists' do
        let(:table_to_drop) { 'hopefully_unused_table' }
        let(:subject) { connection.drop_table(table_to_drop) }
        let(:expected) { true }
        let!(:db) { Sequel.connect(db_url, db_options) }

        before do
          db.create_table(Sequel.qualify schema_name, table_to_drop)
        end

        after do
          db.drop_table(Sequel.qualify(schema_name, table_to_drop), :if_exists => true)
          db.disconnect
        end

        it_behaves_like 'a well-behaved database query'

        it 'should drop a table' do
          connection.table_exists?(table_to_drop).should == true
          connection.drop_table(table_to_drop)
          connection.table_exists?(table_to_drop).should == false
        end
      end

      context 'if the table does not exist' do
        let(:table_to_drop) { 'never_existed' }

        it "doesn't raise an error" do
          expect {
            connection.drop_table(table_to_drop)
          }.not_to raise_error
        end
      end
    end

    describe 'truncate_table' do
      let(:subject) { connection.truncate_table(table_to_truncate) }
      let(:expected) { true }

      context 'if the table exists' do
        let(:table_to_truncate) { 'trunc_table' }
        let!(:db) { Sequel.connect(db_url, db_options) }

        before do
          db = Sequel.connect(db_url, db_options)
          db.execute(<<-SQL)
            CREATE TABLE "test_schema"."trunc_table" (num integer);
            INSERT INTO "test_schema"."trunc_table" (num) VALUES (2)
          SQL
          db.disconnect
        end

        after do
          db.execute(<<-SQL)
            DROP TABLE IF EXISTS "test_schema"."trunc_table"
          SQL
          db.disconnect
        end

        it_behaves_like 'a well-behaved database query'

        it 'should truncate a table' do
          expect {
            connection.truncate_table(table_to_truncate)
          }.to change { connection.fetch(<<-SQL)[0][:num] }.from(1).to(0)
            SELECT COUNT(*) AS num FROM "test_schema"."trunc_table"
          SQL
        end
      end
    end

    describe 'fetch' do
      let(:sql) { 'SELECT 1 AS answer' }
      let(:parameters) { {} }
      let(:subject) { connection.fetch(sql) }
      let(:expected) { [{:answer => 1}] }

      it_behaves_like 'a well-behaved database query'

      it 'sets the search path before any query' do
        stub.proxy(Sequel).connect do |connection|
          stub(connection).execute(anything, anything)
          mock(connection).execute("SET search_path TO \"#{schema_name}\"")
        end

        connection.fetch(sql)
      end

      context 'with SQL parameters' do
        let(:sql) { 'SELECT :num AS answer' }
        let(:parameters) { {:num => 3} }

        it 'succeeds' do
          connection.fetch(sql, parameters).should == [{:answer => 3}]
        end
      end
    end

    describe 'fetch_value' do
      let(:sql) { 'SELECT * FROM ((SELECT 1) UNION (SELECT 2) UNION (SELECT 3)) AS thing' }
      let(:subject) { connection.fetch_value(sql) }
      let(:expected) { 1 }
      let(:schema_name) { "test_schema_with_\"_" }

      it_behaves_like 'a well-behaved database query'

      it 'sets the search path before any query' do
        stub.proxy(Sequel).connect do |connection|
          stub(connection).execute(anything, anything)
          mock(connection).execute("SET search_path TO \"#{schema_name.gsub("\"", "\"\"")}\"")
        end

        connection.fetch_value(sql)
      end
    end

    describe 'stream_sql' do
      let(:sql) { 'SELECT * from thing' }
      let(:expected) { true }
      let(:bucket) {[]}
      let(:execute_options) {{}}
      let(:subject) { connection.stream_sql(sql) { true } }

      before do
        @db = Sequel.connect(db_url, db_options)
        @db.execute("SET search_path TO '#{schema_name}'")
        @db.execute('CREATE TABLE thing (one integer, two integer, three timestamp with time zone, fourth timestamp)')
        @db.execute("INSERT INTO thing VALUES (1, 2, '1999-01-08 04:05:06 -8:00', '1999-01-08 04:05:06')")
        @db.execute("INSERT INTO thing VALUES (3, 4, '1999-07-08 04:05:06 -3:00', '1999-07-08 04:05:06')")
        @db.execute("INSERT INTO thing VALUES (3, 4, '1999-07-08 04:05:06 -3:00', null)")

        connection.stream_sql(sql, execute_options) { |row| bucket << row }
      end

      after do
        @db.execute('DROP TABLE thing')
        @db.disconnect
      end

      it_behaves_like 'a well-behaved database query'

      it 'stores the statement through the cancelable_query' do
        cancelable_query = Object.new
        mock(cancelable_query).store_statement.with_any_args
        connection.stream_sql(sql, {}, cancelable_query) {}
      end

      it 'streams all rows of the results' do
        bucket.should == [{:one => '1', :two => '2', :three => '1999-01-08 04:05:06-08', :fourth => '1999-01-08 04:05:06'},
                          {:one => '3', :two => '4', :three => '1999-07-08 00:05:06-07', :fourth => '1999-07-08 04:05:06'},
                          {:one => '3', :two => '4', :three => '1999-07-08 00:05:06-07', :fourth => 'null'}]
      end

      context 'when a limit is provided' do
        let(:execute_options) {{:limit => 1}}

        it 'only processes part of the results' do
          bucket.should == [{:one => '1', :two => '2', :three => '1999-01-08 04:05:06-08', :fourth => '1999-01-08 04:05:06'}]
        end
      end

      context 'with quiet null' do
        let(:execute_options) {{:quiet_null => true}}

        it 'returns null values as empty string' do
          bucket.last[:fourth].should == ''
        end
      end

      context 'with multiple query results' do
        let(:sql) do
          <<-SQL
            select 1;
            select 2 as "two";
          SQL
        end

        it 'streams the result of the last query' do
          bucket.should == [ {:two => '2'} ]
        end
      end
    end

    describe 'execute' do
      let(:sql) { "SET search_path TO 'public'" }
      let(:parameters) { {} }
      let(:subject) { connection.execute(sql) }
      let(:expected) { true }

      it_behaves_like 'a well-behaved database query'
    end

    describe 'validate_query' do
      let(:subject) {
        connection.validate_query('SELECT * FROM base_table1')
      }
      let(:sequel_connection) { connection.connect! }

      let(:expected) { true }

      it_behaves_like 'a well-behaved database query'

      context 'when the public schema exists' do
        before do
          stub(connection).schema_exists?('public') { true }
        end

        it 'sets the search path on the database connection, with the public schema' do
          mock.proxy(sequel_connection).execute('SET search_path TO "test_schema", public')
          connection.validate_query('SELECT 1')
        end
      end

      context 'when the public schema does not exist' do
        before do
          stub(connection).schema_exists?('public') { false }
        end

        it 'sets the search path on the database connection, without the public schema' do
          mock.proxy(sequel_connection).execute('SET search_path TO "test_schema"')
          connection.validate_query('SELECT 1')
        end
      end


      it 'catches SQL errors' do
        expect {
          connection.validate_query('SELECT WHEREuwiuwiue12321')
        }.to raise_error(PostgresLikeConnection::DatabaseError)
      end

      it "doesn't allow for queries with multiple results" do
        expect {
          connection.validate_query('SELECT 1; SELECT 2;')
        }.to raise_error(PostgresLikeConnection::DatabaseError)
      end

      it "doesn't allow statements that don't return results" do
        expect {
          connection.validate_query('create table test_transaction()')
        }.to raise_error(PostgresLikeConnection::DatabaseError)

        connection.table_exists?('test_transaction').should_not be_true
      end
    end

    describe 'column_info' do
      let(:table_name) { 'base_table1' }
      let(:columns_sql) do
        <<-SQL
        SELECT a.attname, format_type(a.atttypid, a.atttypmod), des.description, a.attnum,
               s.null_frac, s.n_distinct, s.most_common_vals, s.most_common_freqs, s.histogram_bounds,
               c.reltuples
          FROM pg_attribute a
          LEFT JOIN pg_description des
            ON a.attrelid = des.objoid AND a.attnum = des.objsubid
          LEFT JOIN pg_namespace n
            ON n.nspname = :schema
          LEFT JOIN pg_class c
            ON c.relnamespace = n.oid
           AND c.relname = :table
          LEFT JOIN pg_stats s
            ON s.attname = a.attname
           AND s.schemaname = n.nspname
           AND s.tablename = c.relname
          WHERE a.attrelid = '"#{table_name}"'::regclass
          AND a.attnum > 0 AND NOT a.attisdropped
        ORDER BY a.attnum;
        SQL
      end
      let(:expected) do
        db.execute("SET search_path TO #{db.send(:quote_identifier, schema_name)}")
        db.fetch(columns_sql, :schema => schema_name, :table => table_name).all
      end

      context 'with no setup sql' do
        let(:subject) { connection.column_info(table_name, '') }

        it_should_behave_like 'a well-behaved database query'
      end

      context 'with setup sql for a temp view' do
        let(:subject) { connection.column_info('TMP_VIEW', 'CREATE TEMP VIEW "TMP_VIEW" as select * from base_table1;;') }
        let(:expected) do
          db.execute("SET search_path TO #{db.send(:quote_identifier, schema_name)}")
          table_results = db.fetch(columns_sql, :schema => schema_name, :table => table_name).all
          table_results.map do |result|
            result.merge(:description => nil, :null_frac => nil, :n_distinct => nil, :most_common_vals => nil, :most_common_freqs => nil, :histogram_bounds => nil, :reltuples => nil)
          end
        end

        it_should_behave_like 'a well-behaved database query'
      end
    end

    describe 'primary_key_columns' do
      context 'with a primary key' do
        let(:expected) { %w(id2 id3 id) }
        let(:subject) { connection.primary_key_columns('candy') }

        it_should_behave_like 'a well-behaved database query'
      end

      context 'without a primary key' do
        let(:expected) { [] }
        let(:subject) { connection.primary_key_columns('view1') }

        it_should_behave_like 'a well-behaved database query'
      end
    end

    describe 'copy_table_data' do
      let(:destination_table_name) { 'a_new_db_table' }
      let(:source_table_name) { 'base_table1' }
      let(:limit) { nil }
      let(:check_id) { nil }
      let(:user) { Object.new }
      let(:copy_options) {{:limit => limit, :check_id => check_id, :user => user}}
      let(:conn) { Sequel.connect(db_url, db_options) }
      let(:setup_sql) { '' }

      let(:expected) { true }
      subject do
        connection.copy_table_data(%Q{"#{schema_name}"."#{destination_table_name}"}, source_table_name, setup_sql, copy_options)
      end

      before do
        stub(user).id { 'user id' }
        stub(connection).current_user { current_user }
        conn.execute("SET search_path to \"#{schema_name}\"")
        conn.create_table(destination_table_name, :as => "select * from #{schema_name}.base_table1 limit 0")
      end

      after do
        conn.drop_table(destination_table_name, :if_exists => true)
        conn.disconnect
      end

      it_should_behave_like 'a well-behaved database query'

      it 'copies the source data into the destination table' do
        expect {
          subject
        }.to change { conn.fetch("SELECT * from #{destination_table_name}").all.length }
      end

      it 'uses CancelableQuery' do
        mock(CancelableQuery).new(connection, check_id, user).mock!.execute(anything)
        subject
      end

      context 'with a limit' do
        let(:limit) { 3 }

        it 'should only copy that many rows' do
          subject
          conn.fetch("SELECT * from #{destination_table_name}").all.length.should == limit
        end
      end

      context 'with setup sql for a temp view' do
        let(:setup_sql) { 'CREATE TEMP VIEW "TMP_VIEW" as select * from base_table1;;' }
        let(:source_table_name) { 'TMP_VIEW' }

        it_should_behave_like 'a well-behaved database query'
      end
    end

    describe 'count_rows' do
      let(:expected) { db.from(Sequel.qualify(schema_name, table_name)).count }
      let(:subject) { connection.count_rows(table_name) }
      let(:table_name) { 'base_table1' }

      it_should_behave_like 'a well-behaved database query'

      context 'with a crazy name' do
        let(:table_name) { "7_`~!@\#$%^&*()+=[]{}|\\;:',<.>/?" }

        it_should_behave_like 'a well-behaved database query'
      end
    end

    describe 'copy_csv' do
      let(:number_of_lines) { 200 }
      let(:expected) { number_of_lines }
      let(:reader) { java.io.FileReader.new Rails.root.join('spec', 'fixtures', 'test.csv').to_s }
      let(:table_name) { 'csv_to_table' }
      let(:column_names) {['a', 'b', 'c']}
      let(:delimiter) { ',' }
      let(:has_header) { true }
      let(:subject) { connection.copy_csv(reader, table_name, column_names, delimiter, has_header) }
      let!(:db) { Sequel.connect(db_url, db_options) }

      before do
        connection.create_table(table_name, 'a integer, b text, c text', 'DISTRIBUTED RANDOMLY')
      end

      after do
        db.drop_table(Sequel.qualify(schema_name, table_name), :if_exists => true)
        db.disconnect
      end

      it_should_behave_like 'a well-behaved database query'

      it 'should have the correct number of rows in destination table' do
        subject
        connection.count_rows(table_name).should == number_of_lines
      end

      it 'populates the table with the correct data' do
        subject
        result = connection.fetch(<<-SQL)
            SELECT *
            FROM #{table_name}
            ORDER BY a ASC LIMIT 3;
        SQL

        result[0].should == {:a => 1, :b => '1', :c => '1'}
        result[1].should == {:a => 2, :b => '2', :c => '2'}
        result[2].should == {:a => 3, :b => '3', :c => '3'}
      end

    end
  end

  describe 'Database Errors' do
    let(:sequel_exception) {
      exception = Exception.new
      wrapped_exception = Object.new
      stub(exception).wrapped_exception { wrapped_exception }
      stub(exception).message { 'A message' }
      exception
    }

    let(:error) { exception_class.new(sequel_exception) }

    describe 'error_type' do
      context 'when the wrapped error has a sql state error code' do
        before do
          stub(sequel_exception.wrapped_exception).get_sql_state { error_code }
        end

        it 'handles unwrapped exceptions' do
          unwrapped_exception = StandardError.new('I am a message')
          stub(unwrapped_exception).get_sql_state { '3D000' }
          exception = exception_class.new(unwrapped_exception)

          exception.error_type.should == :DATABASE_MISSING
        end

        context 'when the error code is 3D000' do
          let(:error_code) { '3D000' }

          it 'returns :DATABASE_MISSING' do
            error.error_type.should == :DATABASE_MISSING
          end
        end

        context 'when the error code is 28Pxx' do
          let(:error_code) { '28Pbc' }

          it 'returns :INVALID_PASSWORD' do
            error.error_type.should == :INVALID_PASSWORD
          end
        end

        context 'when the error code is 28000' do
          let(:error_code) { '28000' }

          it 'returns :AUTHORIZATION_FAILED' do
            error.error_type.should == :AUTHORIZATION_FAILED
          end
        end

        context 'when the error code is 53300' do
          let(:error_code) { '53300' }

          it 'returns :TOO_MANY_CONNECTIONS' do
            error.error_type.should == :TOO_MANY_CONNECTIONS
          end
        end

        context 'when the error code is 08NNN' do
          let(:error_code) { '08123' }

          it 'returns :DATA_SOURCE_UNREACHABLE' do
            error.error_type.should == :DATA_SOURCE_UNREACHABLE
          end
        end

        context 'when the error code is 42NNN' do
          let(:error_code) { '42123' }

          it 'returns :INVALID_STATEMENT' do
            error.error_type.should == :INVALID_STATEMENT
          end
        end
      end

      context 'when the wrapped error has no sql state error code' do
        it 'returns :GENERIC' do
          error.error_type.should == :GENERIC
        end
      end
    end

    describe 'sanitizing exception messages' do
      let(:error) { exception_class.new(StandardError.new(message)) }

      context 'one kind' do
        let(:message) do
          'foo jdbc:postgresql://somehost:5432/database_name?user=someguy&password=secrets and stuff'
        end

        it 'should sanitize the connection string' do
          error.message.should == 'foo jdbc:postgresql://somehost:5432/database_name?user=xxxx&password=xxxx and stuff'
        end
      end

      context 'another kind' do
        let(:message) do
          'foo jdbc:postgresql://somehost:5432/database_name?user=someguy&password=secrets'
        end

        it 'should sanitize the connection string' do
          error.message.should == 'foo jdbc:postgresql://somehost:5432/database_name?user=xxxx&password=xxxx'
        end
      end

      context 'and another kind' do
        let(:message) do
          'foo jdbc:postgresql://somehost:5432/database_name?user=someguy&password=secrets&somethingelse=blah'
        end

        it 'should sanitize the connection string' do
          error.message.should == 'foo jdbc:postgresql://somehost:5432/database_name?user=xxxx&password=xxxx&somethingelse=blah'
        end
      end

      context 'with other orders' do
        let(:message) do
          'foo jdbc:postgresql://somehost:5432/database_name?password=secrets&user=someguy blah'
        end

        it 'should sanitize the connection string' do
          error.message.should == 'foo jdbc:postgresql://somehost:5432/database_name?password=xxxx&user=xxxx blah'
        end
      end

      context 'when Java::OrgPostgresqlUtil:: starts the message' do
        let(:message) { 'Java::OrgPostgresqlUtil::SOMETHING TERRIBLE HAPPENED!' }

        it 'removes it from the message' do
          error.message.should == 'SOMETHING TERRIBLE HAPPENED!'
        end
      end
    end
  end

  context 'when the user does not have permission to access the database' do
    let(:db) { Sequel.connect(db_url, db_options) }
    let(:restricted_user) { 'user_with_no_access' }
    let(:restricted_password) { 'secret' }

    before do
      db.execute("CREATE USER #{restricted_user} WITH PASSWORD '#{restricted_password}';") rescue nil
      account.db_username = restricted_user
      account.db_password = restricted_password
    end

    after do
      db.execute("DROP USER #{restricted_user};") rescue nil
      db.disconnect
    end

    it 'does not flag the account as invalid_credentials when they connect' do
      expect { connection.connect! }.to raise_error
      account.invalid_credentials.should be_false
    end
  end

  context 'when the user has a crazy password' do
    let(:db) { Sequel.connect(db_url, db_options) }
    let(:user) { 'user_with_crazy_password' }
    let(:password) { '!@#$%^&*()' }

    before do
      db.execute("CREATE USER #{user} WITH PASSWORD '#{password}';") rescue nil
      db.execute("GRANT CONNECT ON DATABASE \"#{database_name}\" TO #{user};")
      account.db_username = user
      account.db_password = password
    end

    after do
      db.execute("DROP USER #{user};") rescue nil
      db.disconnect
    end

    it 'can connect successfully' do
      expect { connection.connect! }.not_to raise_error
    end
  end

  describe 'ssl' do
    context 'when the data source is ssl' do
      before do
        data_source.update_attribute(:ssl, true)
      end

      it 'sends the ssl option to Sequel' do
        db_options[:jdbc_properties][:sslmode].should == 'require'
      end
    end

    context 'when the data source is not ssl' do
      before do
        data_source.update_attribute(:ssl, false)
      end

      it 'does not send the ssl option to Sequel' do
        db_options[:jdbc_properties].should be_nil
      end
    end
  end
end
