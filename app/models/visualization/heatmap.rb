module Visualization
  class Heatmap < Base
    attr_accessor :x_bins, :y_bins, :x_axis, :y_axis, :rows, :type, :filters

    def post_initialize(dataset, attributes)
      @x_axis = attributes[:x_axis]
      @y_axis = attributes[:y_axis]
      @x_bins = attributes[:x_bins].to_i
      @y_bins = attributes[:y_bins].to_i
      @filters = attributes[:filters]
      @type = attributes[:type]
    end

    private

    def complete_fetch(check_id)
      fetch_min_max(@connection, check_id)
      result = CancelableQuery.new(@connection, check_id, current_user).execute(row_sql)
      row_data = result.rows.map { |row| {:x => row[0].to_i, :y => row[1].to_i, :value => row[2].to_i} }
      @rows = fill_missing(row_data)
    end

    def build_min_max_sql
      @sql_generator.heatmap_min_max_sql(
          :dataset => @dataset,
          :x_axis => @x_axis,
          :y_axis => @y_axis
      )
    end

    def build_row_sql
      opts = {
        :dataset => @dataset,
        :x_axis => @x_axis,
        :y_axis => @y_axis,
        :min_x => @min_x,
        :min_y => @min_y,
        :max_x => @max_x,
        :max_y => @max_y,
        :x_bins => @x_bins,
        :y_bins => @y_bins,
        :filters => @filters
      }

      @sql_generator.heatmap_row_sql(opts)
    end

    def fetch_min_max(connection, check_id)
      result = CancelableQuery.new(connection, check_id, current_user).execute(min_max_sql).rows[0]

      @min_x = result[0].to_f
      @max_x = result[1].to_f
      @min_y = result[2].to_f
      @max_y = result[3].to_f
    end

    def fill_missing(rows)
      x_bins_size = ((@max_x - @min_x) / @x_bins.to_f)
      y_bins_size = ((@max_y - @min_y) / @y_bins.to_f)

      filled_rows = []
      (1..@x_bins).each do |x|
        (1..@y_bins).each do |y|
          detected_row = rows.detect { |r| r[:x].to_i == x && r[:y].to_i == y }

          x_bin_start = @min_x + (x_bins_size * (x - 1))
          y_bin_start = @min_y + (y_bins_size * (y - 1))

          x_label = [x_bin_start.round(2), (x_bin_start + x_bins_size).round(2)]
          y_label = [y_bin_start.round(2), (y_bin_start + y_bins_size).round(2)]

          if detected_row
            new_row = detected_row.merge({
              :xLabel => x_label,
              :yLabel => y_label
            })
          else
            new_row = { :x => x, :y => y, :value => 0, :xLabel => x_label, :yLabel => y_label }
          end

          if x == @x_bins
            extra_row = rows.detect { |r| r[:y] == y && r[:x] == (@x_bins+1)}
            extra_row && new_row[:value] += extra_row[:value]
          end

          filled_rows << new_row
        end

          extra_row = rows.detect { |r| r[:x] == x && r[:y] == (@y_bins+1)}
          extra_row && filled_rows.last[:value] += extra_row[:value]
      end

      extra_row = rows.detect { |r| r[:x] == (@x_bins+1) && r[:y] == (@y_bins+1) }
      extra_row && filled_rows.last[:value] += extra_row[:value]

      filled_rows
    end
  end
end
