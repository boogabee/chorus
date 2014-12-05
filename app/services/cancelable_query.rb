require 'java'

class CancelableQuery
  attr_reader :check_id
  @@running_statements = java.util.concurrent.ConcurrentHashMap.new(16, 0.75, 1)

  def format_sql_and_check_id(sql)
    "/*#{@check_id}*/#{sql}"
  end

  def initialize(connection, check_id, user)
    @connection = connection
    @check_id = "#{check_id}_#{user.id}"
  end

  def execute(sql, options = {})
    sql = format_sql_and_check_id(sql)
    options = options.reverse_merge(default_options)
    @connection.prepare_and_execute_statement(sql, options, self)
  ensure
    clean_statement
  end

  def stream(sql, options)
    sql = format_sql_and_check_id(sql)
    SqlStreamer.new(sql, @connection, options, self).enum
  end

  def cancel
    statement = @@running_statements.get(@check_id)
    if statement
      statement.cancel
      @connection ? !busy? : true
    else
      false
    end
  rescue Exception => e
    Rails.logger.debug("Cancelable Query Cancel failed with error #{e.inspect}") if e.respond_to?(:inspect)
    false
  end

  def self.cancel(check_id, user)
    new(nil, check_id, user).cancel
  end

  def busy?
    @connection.fetch("select procpid from pg_stat_activity where current_query LIKE '/*#{@check_id}*/%'").any?
  end

  def store_statement(statement)
    @@running_statements.put(@check_id, statement)
  end

  def clean_statement
    @@running_statements.remove @check_id
  end

  private

  def default_options
    default_options = {:warnings => true}
    default_options.merge!(:timeout => sql_execution_timeout) if sql_execution_timeout > 0
    default_options
  end

  def sql_execution_timeout
    (60 * (ChorusConfig.instance["execution_timeout_in_minutes"] || 0))
  end

end
