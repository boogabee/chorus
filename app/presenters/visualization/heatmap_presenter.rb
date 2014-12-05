module Visualization
  class HeatmapPresenter < Presenter
    include GpdbDataTypes

    def to_hash
      {
        :x_bins => model.x_bins,
        :y_bins => model.y_bins,
        :x_axis => model.x_axis,
        :y_axis => model.y_axis,
        :type => model.type,
        :rows => model.rows,
        :filters => model.filters,
        :columns => [
          { name: 'x', typeCategory: 'WHOLE_NUMBER' },
          { name: 'y', typeCategory: 'WHOLE_NUMBER' },
          { name: 'value', typeCategory: 'REAL_NUMBER' },
          { name: 'xLabel', typeCategory: 'STRING' },
          { name: 'yLabel', typeCategory: 'STRING' }
        ]
      }
    end
  end
end
