module Visualization
  class HistogramPresenter < Presenter
    include GpdbDataTypes

    def to_hash
      {
          :type => model.type,
          :bins => model.bins,
          :x_axis => model.category,
          :filters => model.filters,
          :rows => model.rows,
          :columns => [{name: "bin", type_category: "STRING"}, {name: "frequency", type_category: "WHOLE_NUMBER"}]
      }
    end
  end
end