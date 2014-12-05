module Visualization
  module TeradataSql
    def self.extend_object(obj)
      super
      obj.limit_type = :top
      obj.numeric_cast = 'numeric(32)'
    end

    def boxplot_row_sql(o)
      dataset, values, category, buckets, filters = fetch_opts(o, :dataset, :values, :category, :buckets, :filters)

      filters = filters.present? ? "#{filters.join(' AND ')} AND" : ''

      # td does not support ntile, so approximate with
      # (RANK() OVER(...) - 1) * n / (COUNT(*) OVER (...))
      ntiles_for_each_datapoint = <<-SQL
      SELECT "#{category}", "#{values}", (RANK() OVER (
        PARTITION BY "#{category}"
        ORDER BY "#{values}"
      ) - 1) * 4 / (COUNT(*) OVER (
        PARTITION BY "#{category}"
        ORDER BY "#{values}"
      )) AS ntile
        FROM #{dataset.scoped_name}
          WHERE #{filters} "#{category}" IS NOT NULL AND "#{values}" IS NOT NULL
      SQL

      ntiles_for_each_bucket = <<-SQL
      SELECT "#{category}", ntile, MIN("#{values}") "min", MAX("#{values}") "max", COUNT(*) cnt
        FROM (#{ntiles_for_each_datapoint}) AS ntilesForEachDataPoint
          GROUP BY "#{category}", ntile
      SQL

      limits = limit_clause((buckets * 4).to_s)

      # td does not allow nested ordered analytic functions, so we cannot order by
      # total using this syntax as before...
      ntiles_for_each_bin_with_total = <<-SQL
      SELECT #{limits[:top]} "#{category}", ntile, "min", "max", cnt
        FROM (#{ntiles_for_each_bucket}) AS ntilesForEachBin
        ORDER BY "#{category}", ntile #{limits[:limit]};
      SQL

      ntiles_for_each_bin_with_total
    end
  end
end
