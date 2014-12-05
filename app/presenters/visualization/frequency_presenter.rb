module Visualization
  class FrequencyPresenter < Presenter
    include GpdbDataTypes

    def to_hash
      {
          :bins => model.bins,
          :y_axis => model.category,
          :filters => model.filters,
          :type => model.type,
          :rows => model.rows,
          :columns => [{name: "bucket", type_category: "STRING"}, {name: "count", type_category: "WHOLE_NUMBER"}]
      }
    end
  end
end