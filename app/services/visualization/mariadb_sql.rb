module Visualization
  module MariadbSql

    def self.extend_object(obj)
      super
      obj.limit_type = :limit
    end

    # mariadb does not support windowing functions
    def boxplot_row_sql(o)
      raise NotImplemented
    end

    # mariadb server does not support width_bucket and does not support windowing functions which
    # is the work-around for width_bucket
    def heatmap_min_max_sql(o)
      raise NotImplemented
    end

    def heatmap_row_sql(o)
      raise NotImplemented
    end

    def histogram_min_max_sql(o)
      raise NotImplemented
    end

    def histogram_row_sql(o)
      raise NotImplemented
    end

    # mariadb does not support trunc or date_trunc
    # and needs special implementation
    def timeseries_row_sql(o)
      raise NotImplemented
    end
  end
end
