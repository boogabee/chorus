require 'spec_helper'
require 'timeout'

describe CancelableQuery do
  let(:sql) { "Select 1 as a" }
  let(:check_id) { '0.1234' }
  let(:user) { users(:default) }
  let(:connection) { Object.new }
  let(:cancelable_query) { CancelableQuery.new(connection, check_id, user) }

  before do
    CancelableQuery.class_variable_get(:@@running_statements).clear
  end

  describe "format_sql_and_check_id" do
    it "includes the check_id and the query" do
      cancelable_query.format_sql_and_check_id("select 1").should == "/*#{check_id}_#{user.id}*/select 1"
    end
  end

  describe "execute" do
    let(:options) { {:warnings => true}.merge(extra_options) }
    let(:extra_options) { {} }
    let(:results) { GreenplumSqlResult.new }
    let(:chorus_config_timeout) { nil }

    before do
      mock(connection).prepare_and_execute_statement(cancelable_query.format_sql_and_check_id(sql), options, anything) { results }
      stub(ChorusConfig.instance).[]('execution_timeout_in_minutes') { chorus_config_timeout }
    end

    it "calls to the connection" do
      cancelable_query.execute(sql).should == results
    end

    context "when a limit is passed" do
      let(:extra_options) { {:limit => 123} }
      it "should pass the limit along" do
        cancelable_query.execute(sql, :limit => 123)
      end
    end

    context "when a timeout is passed" do
      let(:extra_options) { {:timeout => 100} }
      it "passes the timeout option through to the greenplum connection" do
        cancelable_query.execute(sql, :timeout => 100)
      end
    end

    context "when a timeout is not passed, but is set in ChorusConfig" do
      let(:chorus_config_timeout) { 75 }
      let(:extra_options) { {:timeout => 60 * chorus_config_timeout} }
      it "uses the timeout from ChorusConfig" do
        cancelable_query.execute(sql)
      end
    end
  end

  describe "execution and cancelling" do
    let(:connection) { Object.new }
    let(:results) { :results }
    let(:still_running) { false }
    let(:fake_statement) { Object.new }
    let(:running_statements) { CancelableQuery.class_variable_get(:@@running_statements) }
    let(:options) { {} }

    before do
      stub(connection).fetch(anything) { still_running ? [1] : [] }
    end

    it "stores the statement" do
      running_statements.should_not have_key("#{check_id}_#{user.id}")
      mock(connection).prepare_and_execute_statement(anything, anything, cancelable_query) do |sql, options, cq|
        cq.store_statement(fake_statement)
        running_statements.should have_key("#{check_id}_#{user.id}")
      end

      cancelable_query.execute(sql, options)
    end

    it "should not blow up if the query is already finished" do
      cancelable_query.cancel.should be_false
    end

    it "should not blow up when threads suck" do
      fake_statement = Object.new
      running_statements[cancelable_query.check_id] = fake_statement
      mock(fake_statement).cancel { raise Exception, "you didn't rescue!" }
      cancelable_query.cancel.should be_false
    end

    context "when the query is no longer running" do
      it "should return false" do
        cancelable_query.cancel.should be_false
      end
    end

    context "when the cancel failed" do
      let(:still_running) { true }

      it "should return false" do
        fake_statement = Object.new
        running_statements[cancelable_query.check_id] = fake_statement
        mock(fake_statement).cancel
        cancelable_query.cancel.should be_false
      end
    end
  end

  context "with a real database connection", :greenplum_integration do
    let(:account) { GreenplumIntegration.real_account }
    let(:user) { account.owner }
    let(:gpdb_data_source) { account.data_source }
    let(:check_id) { '54321' }

    describe "cancel" do
      it 'returns false if the cancel operation is not successful' do
        cancel_connection = gpdb_data_source.connect_with(account)
        CancelableQuery.new(cancel_connection, 0, user).cancel.should == false
      end

      context 'bulk executing' do
        it "cancels the query and throws a query error" do
          cancel_thread = Thread.new do
            cancel_connection = gpdb_data_source.connect_with(account)
            wait_until { get_running_queries_by_check_id(cancel_connection).present? }
            CancelableQuery.new(cancel_connection, check_id, user).cancel.should == true
          end

          query_connection = gpdb_data_source.connect_with(account)
          expect {
            CancelableQuery.new(query_connection, check_id, user).execute("SELECT pg_sleep(15)")
          }.to raise_error PostgresLikeConnection::QueryError
          cancel_thread.join
          get_running_queries_by_check_id(query_connection).should be_nil
        end
      end

      context 'streaming' do
        let!(:cancel_thread) do
          Thread.new do
            connection_to_cancel = gpdb_data_source.connect_with(account)
            wait_until { get_running_queries_by_check_id(connection_to_cancel).present? }
            CancelableQuery.new(connection_to_cancel, check_id, user).cancel.should == true
          end
        end
        let(:query_connection) { gpdb_data_source.connect_with(account) }
        let(:stream) { CancelableQuery.new(query_connection, check_id, user).stream("SELECT pg_sleep(15)", {:rescue_connection_errors => true}) }
        let(:running_statements) { CancelableQuery.class_variable_get(:@@running_statements) }

        it 'cancels the query and throws a query error' do
          stream.to_a.first.should == "ERROR: canceling statement due to user request"
          cancel_thread.join
          get_running_queries_by_check_id(query_connection).should be_nil
        end

        it 'removes the applicable running statement entry' do
          stream.to_a.first
          running_statements.contains_key("#{check_id}_#{user.id}").should be_true

          cancel_thread.join
          stream.close   #This is called by Rack in the application
          running_statements.contains_key("#{check_id}_#{user.id}").should be_false
        end
      end
    end

    describe "busy?" do
      let(:connection) { gpdb_data_source.connect_with(account) }

      after do
        CancelableQuery.new(connection, check_id, user).cancel
      end

      it "returns true when the cancelable query is running" do
        CancelableQuery.new(connection, check_id, user).busy?.should == false

        Thread.new do
          query_connection = gpdb_data_source.connect_with(account)
          CancelableQuery.new(query_connection, check_id, user).execute("SELECT pg_sleep(15)")
        end

        wait_until { get_running_queries_by_check_id(connection).present? }

        CancelableQuery.new(connection, check_id, user).busy?.should == true
      end
    end

    def get_running_queries_by_check_id(conn)
      query = "select current_query from pg_stat_activity;"
      conn.fetch(query).find { |row| row[:current_query].include? check_id }
    end
  end
end
