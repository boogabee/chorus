module Visualization
  class NotImplemented < ApiValidationError
    def initialize
      super :visualization, :not_implemented
    end
  end

  class SqlGenerator
    attr_accessor :limit_type, :numeric_cast, :date_trunc_method

    def initialize(params={})
      @limit_type = params.fetch(:limit, :limit)
      @numeric_cast = params.fetch(:numeric_cast, 'numeric')
      @date_trunc_method = params.fetch(:date_trunc_method, :trunc)
    end

    def frequency_row_sql(o)
      dataset, bins, category, filters = fetch_opts(o, :dataset, :bins, :category, :filters)

      limits = limit_clause(bins)

      query = <<-SQL
        SELECT #{limits[:top]} #{category} AS bucket, count(1) AS counted
          FROM #{dataset.scoped_name}
      SQL
      query << " WHERE #{filters.join(' AND ')}" if filters.present?
      query << " GROUP BY #{category}"
      query << ' ORDER BY counted DESC'
      query << " #{limits[:limit]}" if limits[:limit]
      query
    end

    def boxplot_row_sql(o)
      dataset, values, category, buckets, filters = fetch_opts(o, :dataset, :values, :category, :buckets, :filters)

      filters = filters.present? ? "#{filters.join(' AND ')} AND" : ''

      ntiles_for_each_datapoint = <<-SQL
      SELECT "#{category}", "#{values}", ntile(4) OVER (
        PARTITION BY "#{category}"
        ORDER BY "#{values}"
      ) AS ntile
        FROM #{dataset.scoped_name}
          WHERE #{filters} "#{category}" IS NOT NULL AND "#{values}" IS NOT NULL
      SQL

      ntiles_for_each_bucket = <<-SQL
      SELECT "#{category}", ntile, MIN("#{values}") "min", MAX("#{values}") "max", COUNT(*) cnt
        FROM (#{ntiles_for_each_datapoint}) AS ntilesForEachDataPoint
          GROUP BY "#{category}", ntile
      SQL

      limits = limit_clause((buckets * 4).to_s)

      # this was removed previously, but is a key performance optimization and must remain in place.
      # The query needs to limit the number of buckets, there could be a large number of rows
      ntiles_for_each_bin_with_total = <<-SQL
      SELECT #{limits[:top]} "#{category}", ntile, "min", "max", cnt, SUM(cnt) OVER(
        PARTITION BY "#{category}"
      ) AS total
        FROM (#{ntiles_for_each_bucket}) AS ntilesForEachBin
        ORDER BY total desc, "#{category}", ntile #{limits[:limit]};
      SQL

      ntiles_for_each_bin_with_total
    end

    def heatmap_min_max_sql(o)
      dataset, x_axis, y_axis = fetch_opts(o, :dataset, :x_axis, :y_axis)
      relation = relation(dataset)

      query = relation.project(
          relation[x_axis].minimum.as('xmin'), relation[x_axis].maximum.as('xmax'),
          relation[y_axis].minimum.as('ymin'), relation[y_axis].maximum.as('ymax')
      )

      query.to_sql
    end

    def heatmap_row_sql(o)
      x_axis, x_bins, min_x, max_x = fetch_opts(o, :x_axis, :x_bins, :min_x, :max_x)
      y_axis, y_bins, min_y, max_y = fetch_opts(o, :y_axis, :y_bins, :min_y, :max_y)
      dataset, filters = fetch_opts(o, :dataset, :filters)

      query = <<-SQL
        SELECT x, y, COUNT(*) AS "value" FROM (
          SELECT width_bucket(
            CAST("#{x_axis}" AS #{numeric_cast}),
            CAST(#{min_x} AS #{numeric_cast}),
            CAST(#{max_x} AS #{numeric_cast}),
            #{x_bins}
          ) AS x,
          width_bucket( CAST("#{y_axis}" AS #{numeric_cast}),
            CAST(#{min_y} AS #{numeric_cast}),
            CAST(#{max_y} AS #{numeric_cast}),
            #{y_bins}
          ) AS y FROM ( SELECT * FROM #{dataset.scoped_name}
      SQL

      query +=  ' WHERE ' + filters.join(' AND ') if filters.present?

      query += <<-SQL
        ) subquery
          WHERE "#{x_axis}" IS NOT NULL
          AND "#{y_axis}" IS NOT NULL) foo
          GROUP BY x, y
      SQL

      query
    end

    def histogram_min_max_sql(o)
      relation = relation(o[:dataset])
      category = o[:category]

      query = relation.
          project(relation[category].minimum.as('"min"'), relation[category].maximum.as('"max"'))

      query.to_sql
    end

    def histogram_row_sql(o)
      dataset, min, max, bins, filters, category = fetch_opts(o, :dataset, :min, :max, :bins, :filters, :category)
      relation = relation(dataset)
      scoped_category = %(#{dataset.scoped_name}."#{category}")

      width_bucket = "width_bucket(CAST(#{scoped_category} as #{numeric_cast}), CAST(#{min} as #{numeric_cast}), CAST(#{max} as #{numeric_cast}), #{bins})"

      query = relation.
          group(width_bucket).
          project(Arel.sql(width_bucket).as('bucket'), Arel.sql("COUNT(#{width_bucket})").as('frequency')).
          where(relation[category].not_eq(nil))

      query = query.where(Arel.sql(filters.join(' AND '))) if filters.present?

      query.to_sql
    end

    def timeseries_row_sql(o)
      time, time_interval, aggregation = fetch_opts(o, :time, :time_interval, :aggregation)
      value, filters, pattern = fetch_opts(o, :value, :filters, :pattern)
      dataset = o[:dataset]

      date_trunc = date_trunc_expression(time, time_interval)

      query = <<-SQL
        SELECT #{aggregation}("#{value}"), to_char(#{date_trunc}, '#{pattern}')
          FROM #{dataset.scoped_name}
      SQL
      query << " WHERE #{filters.join(' AND ')}" if filters.present?
      query << <<-SQL
        GROUP BY #{date_trunc}
        ORDER BY #{date_trunc} ASC
      SQL

      query
    end

    private

    def limit_clause(limit)
      {
          :top => limit_type == :top ? "TOP #{limit}" : '',
          :limit => limit_type == :limit ? "LIMIT #{limit}" : ''
      }
    end

    def date_trunc_expression(column, time_interval)
      if date_trunc_method == :date_trunc
        %(date_trunc('#{time_interval}', "#{column}"))
      else
        %(TRUNC("#{column}", '#{time_interval}'))
      end
    end

    def relation(dataset)
      @relation ||= Arel::Table.new(dataset.scoped_name)
    end

    def fetch_opts(opts, *keys)
      keys.map { |key| opts.fetch key }
    end
  end
end
