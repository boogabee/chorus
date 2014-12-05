module Visualization
  class Boxplot < Base
    attr_accessor :rows, :buckets, :category, :values, :filters, :type

    def post_initialize(dataset, attributes)
      @buckets = attributes[:bins].to_i
      @category = attributes[:x_axis]
      @values = attributes[:y_axis]
      @filters = attributes[:filters]
      @type = attributes[:type]
    end

    def complete_fetch(check_id)
      result = CancelableQuery.new(@connection, check_id, current_user).execute(row_sql)
      ntiles_for_each_bucket = result.rows.map { |row| {:bucket => row[0], :ntile => row[1].to_i, :min => row[2].to_f, :max => row[3].to_f, :count => row[4].to_i} }
      @rows = BoxplotSummary.summarize(ntiles_for_each_bucket, @buckets)
    end

    private

    def build_row_sql
      @sql_generator.boxplot_row_sql(
          :dataset => @dataset,
          :values => @values,
          :category => @category,
          :buckets => @buckets,
          :filters => @filters
      )
    end
  end
end
