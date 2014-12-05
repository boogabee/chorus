module Visualization
  class BoxplotPresenter < Presenter
    include GpdbDataTypes
    
    def to_hash
      {
          :type => model.type,
          :bins => model.buckets,
          :x_axis => model.category,
          :y_axis => model.values,
          :rows => model.rows,
          :filters => model.filters,
          :columns => [
              {name: "bucket", type_category: "STRING"},
              {name: "min", type_category: "REAL_NUMBER"},
              {name: "firstQuartile", type_category: "REAL_NUMBER"},
              {name: "median", type_category: "REAL_NUMBER"},
              {name: "thirdQuartile", type_category: "REAL_NUMBER"},
              {name: "max", type_category: "REAL_NUMBER"},
              {name: "percentage", type_category: "STRING"}
          ]
      }
    end
  end
end