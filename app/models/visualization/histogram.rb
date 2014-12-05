module Visualization
  class Histogram < Base
    attr_accessor :rows, :bins, :category, :filters, :type

    def post_initialize(dataset, attributes)
      @type = attributes[:type]
      @bins = attributes[:bins].to_i
      @category = attributes[:x_axis]
      @filters = attributes[:filters]
    end

    private

    def complete_fetch(check_id)
      min_max_result = CancelableQuery.new(@connection, check_id, current_user).execute(min_max_sql)

      @min = min_max_result.rows[0][0].to_f
      @max = min_max_result.rows[0][1].to_f

      result = CancelableQuery.new(@connection, check_id, current_user).execute(row_sql)
      row_data = result.rows.map { |row| {:bin => row[0].to_i, :frequency => row[1].to_i} }

      @rows = massage(row_data)
    end

    def build_row_sql
      opts = {
          :dataset => @dataset,
          :category => @category,
          :min => @min,
          :max => @max,
          :bins => @bins,
          :filters => @filters
      }

      @sql_generator.histogram_row_sql(opts)
    end

    def build_min_max_sql
      opts = {
          :dataset => @dataset,
          :category => @category
      }

      @sql_generator.histogram_min_max_sql(opts)
    end

    def massage(row_data)
      new_row_data = []
      bin_width = ((@max - @min)/@bins)

      for i in 1..@bins
        detected_row = row_data.detect { |r| r[:bin] == i }

        low_range = ((i-1) * bin_width + @min).round(1)
        high_range = (i * bin_width + @min).round(1)

        if detected_row
          new_row_data << {:bin => [low_range, high_range],
                           :frequency => detected_row[:frequency]}
        else
          new_row_data << {:bin => [low_range, high_range],
                           :frequency => 0}
        end
      end

      extra_bin = row_data.detect { |r| r[:bin] == (@bins + 1) }
      new_row_data[@bins-1][:frequency] = new_row_data[@bins-1][:frequency] + extra_bin[:frequency] if extra_bin

      new_row_data
    end
  end
end
