module Visualization
  module OracleSql
    def frequency_row_sql(o)
      dataset, bins, category, filters = fetch_opts(o, :dataset, :bins, :category, :filters)

      query = <<-SQL
      SELECT * FROM (
        SELECT "#{category}" AS "bucket", count(1) AS "counted"
          FROM #{dataset.scoped_name}
      SQL

      query << " WHERE #{filters.join(' AND ')}" if filters.present?

      query << <<-SQL
          GROUP BY "#{category}"
          ORDER BY "counted" DESC
        ) WHERE ROWNUM <= #{bins}
      SQL

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
        FROM (#{ntiles_for_each_datapoint}) ntilesForEachDataPoint
          GROUP BY "#{category}", ntile
      SQL

      ntiles_for_each_bin_with_total = <<-SQL
      SELECT "#{category}", ntile, "min", "max", cnt, SUM(cnt) OVER(
        PARTITION BY "#{category}"
      ) AS total
        FROM (#{ntiles_for_each_bucket}) ntilesForEachBin
        ORDER BY total desc, "#{category}", ntile
      SQL

      result = <<-SQL
        SELECT * FROM (#{ntiles_for_each_bin_with_total})
          WHERE ROWNUM <= #{buckets}
      SQL

      result
    end

    # def timeseries_row_sql(o)
    #   raise NotImplemented
    # end
  end
end
