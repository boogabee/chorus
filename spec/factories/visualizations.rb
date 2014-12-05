require 'factory_girl'

FactoryGirl.define do
  factory :visualization_frequency, :class => Visualization::Frequency do
    bins 20
    category "title"
    filters ["\"1000_songs_test_1\".year > '1980'"]
    association :dataset, :factory => :gpdb_table
    association :schema, :factory => :gpdb_schema
  end

  factory :visualization_histogram, :class => Visualization::Histogram do
    bins 20
    category "airport_cleanliness"
    filters ["\"2009_sfo_customer_survey\".terminal > 5"]
    association :dataset, :factory => :gpdb_table
    association :schema, :factory => :gpdb_schema
  end

  factory :visualization_heatmap, :class => Visualization::Heatmap do
    x_bins 3
    y_bins 3
    x_axis "theme"
    y_axis "artist"
    association :dataset, :factory => :gpdb_table
    association :schema, :factory => :gpdb_schema
  end

  factory :visualization_timeseries, :class => Visualization::Timeseries do
    time "time_value"
    value "column1"
    time_interval "month"
    aggregation "sum"
    association :dataset, :factory => :gpdb_table
    association :schema, :factory => :gpdb_schema
  end

  factory :visualization_boxplot, :class => Visualization::Boxplot do
    buckets 10
    category "category"
    values "column1"
    association :dataset, :factory => :gpdb_table
    association :schema, :factory => :gpdb_schema
  end
end