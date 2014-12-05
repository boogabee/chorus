module Visualization
  class Timeseries < Base
    attr_accessor :rows, :time, :value, :time_interval, :aggregation, :filters, :type

    def post_initialize(dataset, attributes)
      @type = attributes[:type]
      @time = attributes[:x_axis]
      @value = attributes[:y_axis]
      @time_interval = attributes[:time_interval]
      @aggregation = attributes[:aggregation]
      @filters = attributes[:filters]
    end

    private

    def complete_fetch(check_id)
      result = CancelableQuery.new(@connection, check_id, current_user).execute(row_sql)

      raise ApiValidationError.new(:base, :too_many_rows) if result.rows.count > 1000
      @rows = result.rows.map { |row| {:value => row[0].to_f.round(3), :time => row[1]} }
    end

    def build_row_sql
      opts = {
          :dataset => @dataset,
          :time => @time,
          :time_interval => @time_interval,
          :aggregation => @aggregation,
          :value => @value,
          :filters => @filters,
          :pattern => pattern(@time_interval)
      }

      @sql_generator.timeseries_row_sql(opts)
    end

    def pattern(time_interval)
      if 'day' == time_interval || 'week'==time_interval
        pattern = 'yyyy-MM-dd'
      elsif 'month'== time_interval
        pattern = 'yyyy-MM'
      elsif 'year'== time_interval
        pattern = 'yyyy'
      else
        pattern = 'yyyy-MM-dd hh:mm:ss'
      end

      pattern
    end
  end
end
