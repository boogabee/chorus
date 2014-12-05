require 'spec_helper'

describe OracleConnection, :oracle_integration do
  let(:data_source) { OracleIntegration.real_data_source }
  let(:database_name) { data_source.db_name }
  let(:account) { OracleIntegration.real_account }
  let(:exception_class) { OracleConnection::DatabaseError }

  let(:options) { { :logger => Rails.logger } }
  let(:connection) { OracleConnection.new(data_source, account, options) }
  let(:db_url) { connection.db_url }
  let(:db_options) { connection.db_options }
  let(:db) { Sequel.connect(db_url, db_options) }

  before do
    stub.proxy(Sequel).connect.with_any_args
  end

  it_should_behave_like "a data source connection" do
    let(:empty_set_sql) { "SELECT 1 FROM dual where 1=2" }
    let(:sql) { "SELECT 1 as col1 FROM dual" }
    let(:sql_with_parameter) { "SELECT :param as col1 FROM dual" }
  end

  describe "#connect!" do
    it "should connect" do
      mock.proxy(Sequel).connect(db_url, hash_including(:test => true))

      connection.connect!
      connection.connected?.should be_true
    end

    context "when oracle is not configured" do
      before do
        stub(ChorusConfig.instance).oracle_configured? { false }
      end

      it "raises an error" do
        expect {
          connection.connect!
        }.to raise_error(DataSourceConnection::DriverNotConfigured) { |error|
          error.data_source.should == 'Oracle'
        }
      end
    end
  end

  describe "#schemas" do
    let(:schema_blacklist) {
      ["OBE", "SCOTT", "DIP", "ORACLE_OCM", "XS$NULL", "MDDATA", "SPATIAL_WFS_ADMIN_USR", "SPATIAL_CSW_ADMIN_USR", "IX", "SH", "PM", "BI", "DEMO", "HR1", "OE1", "XDBPM", "XDBEXT", "XFILES", "APEX_PUBLIC_USER", "TIMESTEN", "CACHEADM", "PLS", "TTHR", "APEX_REST_PUBLIC_USER", "APEX_LISTENER", "OE", "HR", "HR_TRIG", "PHPDEMO", "APPQOSSYS", "WMSYS", "OWBSYS_AUDIT", "OWBSYS", "SYSMAN", "EXFSYS", "CTXSYS", "XDB", "ANONYMOUS", "OLAPSYS", "APEX_040200", "ORDSYS", "ORDDATA", "ORDPLUGINS", "FLOWS_FILES", "SI_INFORMTN_SCHEMA", "MDSYS", "DBSNMP", "OUTLN", "MGMT_VIEW", "SYSTEM", "SYS"]
    }

    let(:schema_list_sql) {
      blacklist = schema_blacklist.join("', '")
      <<-SQL
        SELECT DISTINCT OWNER as name
        FROM ALL_OBJECTS
        WHERE OBJECT_TYPE IN ('TABLE', 'VIEW') AND OWNER NOT IN ('#{blacklist}')
      SQL
    }

    let(:expected) { db.fetch(schema_list_sql).all.collect { |row| row[:name] } }
    let(:subject) { connection.schemas }

    it_should_behave_like "a well-behaved database query"
  end

  describe "#schema_exists?" do
    let(:schema_name) { OracleIntegration.schema_name }
    let(:subject) { connection.schema_exists?(schema_name) }
    let(:expected) { true }

    it_should_behave_like "a well-behaved database query"

    context "when the schema doesn't exist" do
      let(:schema_name) { "does_not_exist" }

      it 'returns false' do
        connection.schema_exists?(schema_name).should be_false
      end
    end
  end

  describe "#set_timeout" do
    let (:statement) { Object.new }

    it "calls setQueryTimeout on statement" do
      mock(statement).set_query_timeout(123)
      connection.set_timeout(123, statement)
    end

  end

  describe '#version' do
    let(:subject) { connection.version }
    let(:expected) { /11\.2\.0.*/ }
    let(:use_match_matcher) { true }

    it_should_behave_like 'a well-behaved database query'
  end

  describe "#stream_sql" do
    let(:sql) { "SELECT * from \"#{OracleIntegration.schema_name}\".NEWTABLE" }

    let(:subject) {
      connection.stream_sql(sql) { true }
    }
    let(:expected) { true }

    it_behaves_like "a well-behaved database query"

    it "streams all rows of the results" do
      bucket = []
      connection.stream_sql(sql) { |row| bucket << row }

      bucket.length.should == 10
      bucket.each_with_index do |row, index|
        index = index + 1
        row.should == {:ID => index.to_s, :ROWNAME => "row_#{index}"}
      end
    end

    it 'stores the statement through the cancelable_query' do
      cancelable_query = Object.new
      mock(cancelable_query).store_statement.with_any_args
      connection.stream_sql(sql, {}, cancelable_query) {}
    end

    context "when a limit is provided" do
      it "only processes part of the results" do
        bucket = []
        connection.stream_sql(sql, {:limit => 1}) { |row| bucket << row }

        bucket.should == [{:ID => "1", :ROWNAME => "row_1"}]
      end
    end
  end

  describe "#prepare_and_execute_statement" do
    let(:sql) { "SELECT * from \"#{OracleIntegration.schema_name}\".NEWTABLE" }
    context "when a timeout is specified" do
      let(:execute_options) { {:timeout => 1} }
      let(:too_many_rows) { 2500 }
      let(:sql) do
        sql = <<-SQL
            INSERT INTO "#{OracleIntegration.schema_name}".BIG_TABLE
        SQL
        sql + (1..too_many_rows).map do |count|
          <<-SQL
            (SELECT #{count} FROM "#{OracleIntegration.schema_name}".BIG_TABLE)
          SQL
        end.join(" UNION ")
      end

      # TODO: New oracle box seems to be too fast to get this to timeout consistently
      #around do |example|
      #  connection.execute(<<-SQL) rescue nil
      #    CREATE TABLE "#{OracleIntegration.schema_name}".BIG_TABLE
      #      (COLUMN1 NUMBER)
      #  SQL
      #
      #  connection.execute <<-SQL
      #      INSERT INTO "#{OracleIntegration.schema_name}".BIG_TABLE VALUES (0)
      #  SQL
      #
      #  example.run
      #
      #  connection.execute <<-SQL
      #    DROP TABLE "#{OracleIntegration.schema_name}".BIG_TABLE
      #  SQL
      #end
      #
      #it "should raise a timeout error (which is 'requested cancel' on oracle)" do
      #  expect do
      #    connection.prepare_and_execute_statement sql, execute_options
      #  end.to raise_error(DataSourceConnection::QueryError, /requested cancel/)
      #end
    end

    it 'stores the statement through the cancelable_query' do
      cancelable_query = Object.new
      mock(cancelable_query).store_statement.with_any_args
      connection.prepare_and_execute_statement(sql, {}, cancelable_query)
    end
  end

  describe "methods within a schema" do
    let(:schema_name) { OracleIntegration.schema_name }
    let(:connection) { OracleConnection.new(data_source, account, options.merge(:schema => schema_name)) }

    describe "#datasets" do
      let(:dataset_list_sql) {
        <<-SQL
        SELECT * FROM (
          SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}'
          UNION
          SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = '#{schema_name}'
        )
        ORDER BY name
        SQL
      }

      let(:expected) { db.fetch(dataset_list_sql).all }
      let(:subject) { connection.datasets }

      it_should_behave_like "a well-behaved database query"

      context "when a limit is passed" do
        let(:dataset_list_sql) {
          <<-SQL
        SELECT * FROM (
          SELECT * FROM (
            SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = '#{schema_name}'
            UNION
            SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}'
          )
          ORDER BY name
        )
        WHERE rownum <= 2
          SQL
        }

        let(:expected) { db.fetch(dataset_list_sql).all }
        let(:subject) { connection.datasets(:limit => 2) }

        it_should_behave_like "a well-behaved database query"
      end

      context "when a name filter is passed" do
        let(:subject) { connection.datasets(:name_filter => name_filter) }

        context "and the filter does not contain LIKE wildcards" do
          let(:name_filter) {'nEWer'}
          let(:dataset_list_sql) {
            <<-SQL
          SELECT * FROM (
            SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(TABLE_NAME, 'EWer', 'i')
            UNION
            SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(VIEW_NAME, 'EWer', 'i'))
          ORDER BY name
            SQL
          }
          let(:expected) { db.fetch(dataset_list_sql).all }

          it_should_behave_like "a well-behaved database query"
        end

        context "and the filter contains LIKE wildcards" do
          let(:name_filter) {'_T'}

          it "only returns datasets which contain '_T' in their names (it should not use _ as a wildcard)" do
            subject.length.should > 0
            subject.each { |dataset| dataset[:name].should match /_T/i }
          end
        end
      end

      context "when showing only tables" do
        let(:dataset_list_sql) {
          <<-SQL
        SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}'
        ORDER BY name
          SQL
        }
        let(:expected) { db.fetch(dataset_list_sql).all }
        let(:subject) { connection.datasets(:tables_only => true) }

        it_should_behave_like "a well-behaved database query"
      end

      context "when multiple options are passed" do
        let(:dataset_list_sql) {
          <<-SQL
        SELECT * FROM (
          SELECT * FROM (
            SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(TABLE_NAME, 'EWer', 'i')
            UNION
            SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(VIEW_NAME, 'EWer', 'i')
          )
          ORDER BY name
        )
        WHERE rownum <= 1
          SQL
        }
        let(:expected) { db.fetch(dataset_list_sql).all }
        let(:subject) { connection.datasets(:name_filter => 'nEWer', :limit => 1) }

        it_should_behave_like "a well-behaved database query"
      end
    end

    describe "#datasets_count" do
      let(:connection) { OracleConnection.new(data_source, account, options.merge(:schema => schema_name)) }
      let(:schema_name) { OracleIntegration.schema_name }
      let(:dataset_list_sql) {
        <<-SQL
        SELECT count(*) FROM (
          SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}'
          UNION
          SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = '#{schema_name}'
        )
        SQL
      }

      let(:expected) { db.fetch(dataset_list_sql).single_value }
      let(:subject) { connection.datasets_count }

      it_should_behave_like "a well-behaved database query"

      context "when a name filter is passed" do
        let(:dataset_list_sql) {
          <<-SQL
        SELECT count(*) FROM (
          SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(TABLE_NAME, 'EWer', 'i')
          UNION
          SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = '#{schema_name}' AND REGEXP_LIKE(VIEW_NAME, 'EWer', 'i')
        )
          SQL
        }
        let(:expected) { db.fetch(dataset_list_sql).single_value }
        let(:subject) { connection.datasets_count(:name_filter => 'nEWer') }

        it_should_behave_like "a well-behaved database query"
      end

      context "when showing only tables" do
        let(:dataset_list_sql) {
          <<-SQL
        SELECT count(*) FROM ALL_TABLES WHERE OWNER = '#{schema_name}'
          SQL
        }
        let(:expected) { db.fetch(dataset_list_sql).single_value }
        let(:subject) { connection.datasets_count(:tables_only => true) }

        it_should_behave_like "a well-behaved database query"
      end
    end

    describe "#metadata_for_dataset" do
      let(:schema_name) { OracleIntegration.schema_name }
      let(:expected) { {:column_count => 2} }
      let(:subject) { connection.metadata_for_dataset('TWO_COLUMN_TABLE') }

      it_should_behave_like "a well-behaved database query"
    end

    describe "#table_exists?" do
      let(:subject) { connection.table_exists?(table_name) }
      let(:expected) { true }

      context 'when the table exists' do
        context 'with an all caps table name' do
          let(:table_name) { 'NEWTABLE' }
          it_should_behave_like 'a well-behaved database query'
        end

        context 'with a lower case table name' do
          let(:table_name) { 'lowercase_table' }
          it_should_behave_like 'a well-behaved database query'
        end
      end

      context "when the table doesn't exist" do
        let(:table_name) { "MISSING_TABLE" }
        let(:expected) { false }

        it_should_behave_like "a well-behaved database query"
      end

      context "when the table name given is nil" do
        let(:table_name) { nil }
        let(:expected) { false }

        it_should_behave_like "a well-behaved database query"
      end
    end

    describe "#view_exists?" do
      let(:subject) { connection.view_exists?(view_name) }

      context 'when the view exists' do
        let(:expected) { true }

        context 'with an all caps view name' do
          let(:view_name) { 'NEWVIEW' }
          it_behaves_like 'a well-behaved database query'
        end

        context 'with a lowercase view name' do
          let(:view_name) { 'lowercase_view' }
          it_behaves_like 'a well-behaved database query'
        end
      end

      context "when the view doesn't exist" do
        let(:view_name) { "MISSING_VIEW" }
        let(:expected) { false }

        it_behaves_like 'a well-behaved database query'
      end

      context "when the view name given is nil" do
        let(:view_name) { nil }
        let(:expected) { false }

        it_behaves_like 'a well-behaved database query'
      end
    end

    describe "#column_info" do
      let(:table_name) { "NEWERTABLE" }
      let(:columns_sql) do
        <<-SQL
          SELECT COLUMN_NAME as attname, DATA_TYPE as format_type, COLUMN_ID as attnum
          FROM ALL_TAB_COLUMNS
          WHERE TABLE_NAME = :table AND OWNER = :schema
          ORDER BY attnum
        SQL
      end
      let(:expected) do
        db.fetch(columns_sql, :schema => schema_name, :table => table_name).all
      end

      let(:subject) { connection.column_info(table_name, 'ignored setup sql to be consistent with other datasource connections') }

      it_should_behave_like "a well-behaved database query"
    end

    describe "primary_key_columns" do
      context "with a primary key" do
        let(:expected) { %w(COLUMN2 COLUMN1) }
        let(:subject) { connection.primary_key_columns('WITH_COMPOSITE_KEY') }
        it_should_behave_like "a well-behaved database query"
      end

      context "without a primary key" do
        let(:expected) { [] }
        let(:subject) { connection.primary_key_columns('NEWTABLE') }

        it_should_behave_like "a well-behaved database query"
      end
    end
  end

  describe "OracleConnection::DatabaseError" do
    let(:sequel_exception) {
      exception = Exception.new
      wrapped_exception = Object.new
      stub(exception).wrapped_exception { wrapped_exception }
      stub(exception).message { "A message" }
      exception
    }

    let(:error) do
      OracleConnection::DatabaseError.new(sequel_exception)
    end

    describe "error_type" do
      context "when the wrapped error has an error code" do
        before do
          stub(sequel_exception.wrapped_exception).get_error_code { error_code }
        end

        context "when the error code is 12514" do
          let(:error_code) { 12514 }

          it "returns :DATABASE_MISSING" do
            error.error_type.should == :DATABASE_MISSING
          end
        end

        context "when the error code is 1017" do
          let(:error_code) { 1017 }

          it "returns :INVALID_PASSWORD" do
            error.error_type.should == :INVALID_PASSWORD
          end
        end

        context "when the error code is 17002" do
          let(:error_code) { 17002 }

          it "returns :DATA_SOURCE_UNREACHABLE" do
            error.error_type.should == :DATA_SOURCE_UNREACHABLE
          end
        end
      end

      context "when the wrapped error has no sql state error code" do
        it "returns :GENERIC" do
          error.error_type.should == :GENERIC
        end
      end
    end

    describe "sanitizing exception messages" do
      let(:error) { OracleConnection::DatabaseError.new(StandardError.new(message)) }

      context "when the error as username and password" do
        let(:message) do
          "foo jdbc:oracle:thin:system/oracle@//chorus-oracle:8888/orcl and stuff"
        end

        it "replaces them with x'es" do
          error.message.should == "foo jdbc:oracle:thin:xxxx/xxxx@//chorus-oracle:8888/orcl and stuff"
        end
      end

      context "when Java::JavaSql:: starts the message" do
        let(:message) { "Java::JavaSql::SOMETHING TERRIBLE HAPPENED!" }

        it "removes it from the message" do
          error.message.should == "SOMETHING TERRIBLE HAPPENED!"
        end
      end
    end
  end

  context "when the user doesn't have permission to access some object in the database" do
    let(:db) { Sequel.connect(db_url, db_options) }
    let(:schema_name) { OracleIntegration.schema_name }
    let(:restricted_user) { "user_with_no_access" }
    let(:restricted_password) { "secret" }

    before do
      db.execute("CREATE USER #{restricted_user} IDENTIFIED BY #{restricted_password}") rescue nil
      db.execute("GRANT CREATE SESSION TO #{restricted_user}")

      account.db_username = restricted_user
      account.db_password = restricted_password
    end

    after do
      connection.disconnect
      db.execute("DROP USER #{restricted_user}")
      db.disconnect
    end

    it "does not flag the account as invalid_credentials when they access an object for which they don't have permission" do
      connection.connect!
      expect { connection.execute("SELECT * FROM #{schema_name}.NEWTABLE") }.to raise_error
      account.invalid_credentials.should be_false
    end
  end
  
  context "when the user has a crazy password" do
    let(:db) { Sequel.connect(db_url, db_options) }
    let(:user) { "user_with_crazy_password" }
    let(:password) { '!@#$%^&*()' }

    before do
      db.execute("CREATE USER #{user} IDENTIFIED BY \"#{password}\"")
      db.execute("GRANT CREATE SESSION TO #{user}")

      account.db_username = user
      account.db_password = password
    end

    after do
      connection.disconnect
      db.execute("DROP USER #{user}")
      db.disconnect
    end

    it "can connect successfully" do
      expect { connection.connect! }.not_to raise_error
    end
  end
end