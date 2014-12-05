require 'csv'

class SqlStreamer
  class ClosableEnumerator < Enumerator
    def initialize(cq, &proc)
      @cq = cq
      super &proc
    end
    def close
      @cq.clean_statement if @cq
    end
  end

  def initialize(sql, connection, options = {}, cancelable_query = nil)
    @sql = sql
    @connection = connection
    @target_is_greenplum = options[:target_is_greenplum]
    @show_headers = options[:show_headers] == false ? false : true

    @stream_options = {}
    @stream_options[:limit] = options[:row_limit] if options[:row_limit].to_i > 0
    @stream_options[:quiet_null] = !!options[:quiet_null]
    @stream_options[:rescue_connection_errors] = !!options[:rescue_connection_errors]
    @cancelable_query = cancelable_query
  end

  def enum
    first_row = @show_headers
    no_results = true

    ClosableEnumerator.new(@cancelable_query) do |y|
      begin
        @connection.stream_sql(@sql, @stream_options, @cancelable_query) do |row|
          no_results = false

          if first_row && @show_headers
            y << format_row(row.keys)
            first_row = false
          end

          y << format_row(row.values)
        end

        if no_results && @show_headers
          y << empty_results_error
        end
      rescue Exception => e
        raise e unless @stream_options[:rescue_connection_errors]
        y << e.message
      end
      #Ruby enumerators leak active record connections due to details of Fibers in jRuby (at least ~1.7.0)
      #If you take out this line, you may run out of active record connections if you stream too much.
      ActiveRecord::Base.connection.close
    end
  end

  private

  def empty_results_error
    "The query returned no rows"
  end

  def format_for_greenplum(value)
    if value.is_a?(String)
      return '' if value == '\0'
      value.gsub(/(\\n|\\r)/, ' ')
    else
      value
    end
  end

  def format_row(row)
    if @target_is_greenplum
      row.map { |value| format_for_greenplum(value) }
    else
      row
    end.to_csv
  end
end