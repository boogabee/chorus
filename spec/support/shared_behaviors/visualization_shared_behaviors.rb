shared_examples 'a heatmap visualization' do
  # provide dataset and data_source_account

  let(:visualization) do
    Visualization::Heatmap.new(dataset, {
        :x_bins => 3,
        :y_bins => 3,
        :x_axis => 'column1',
        :y_axis => 'column2',
        :filters => filters
    })
  end

  describe '#fetch' do
    before do
      set_current_user users(:default)
      visualization.fetch!(data_source_account, 12345)
    end

    context 'no filters' do
      let(:filters) { nil }

      it 'creates the SQL based on the grouping and bins' do
        visualization.rows.should == [
            {:x => 1, :y => 1, :value => 1, :xLabel => [2.0, 3.33], :yLabel => [2.0, 3.33]},
            {:x => 1, :y => 2, :value => 1, :xLabel => [2.0, 3.33], :yLabel => [3.33, 4.67]},
            {:x => 1, :y => 3, :value => 1, :xLabel => [2.0, 3.33], :yLabel => [4.67, 6.0]},
            {:x => 2, :y => 1, :value => 1, :xLabel => [3.33, 4.67], :yLabel => [2.0, 3.33]},
            {:x => 2, :y => 2, :value => 1, :xLabel => [3.33, 4.67], :yLabel => [3.33, 4.67]},
            {:x => 2, :y => 3, :value => 1, :xLabel => [3.33, 4.67], :yLabel => [4.67, 6.0]},
            {:x => 3, :y => 1, :value => 1, :xLabel => [4.67, 6.0], :yLabel => [2.0, 3.33]},
            {:x => 3, :y => 2, :value => 1, :xLabel => [4.67, 6.0], :yLabel => [3.33, 4.67]},
            {:x => 3, :y => 3, :value => 2, :xLabel => [4.67, 6.0], :yLabel => [4.67, 6.0]}
        ]
      end
    end

    context 'with filters' do
      let(:filters) { [%("#{dataset.name}"."category" <> 'green'), %("#{dataset.name}"."category" <> 'cornflower blue')] }

      it 'returns the frequency data based on the filtered dataset' do
        visualization.rows.should == [
            {:x => 1, :y => 1, :value => 1, :xLabel => [2.0, 3.33], :yLabel => [2.0, 3.33]},
            {:x => 1, :y => 2, :value => 1, :xLabel => [2.0, 3.33], :yLabel => [3.33, 4.67]},
            {:x => 1, :y => 3, :value => 1, :xLabel => [2.0, 3.33], :yLabel => [4.67, 6.0]},
            {:x => 2, :y => 1, :value => 1, :xLabel => [3.33, 4.67], :yLabel => [2.0, 3.33]},
            {:x => 2, :y => 2, :value => 1, :xLabel => [3.33, 4.67], :yLabel => [3.33, 4.67]},
            {:x => 2, :y => 3, :value => 1, :xLabel => [3.33, 4.67], :yLabel => [4.67, 6.0]},
            {:x => 3, :y => 1, :value => 1, :xLabel => [4.67, 6.0], :yLabel => [2.0, 3.33]},
            {:x => 3, :y => 2, :value => 0, :xLabel => [4.67, 6.0], :yLabel => [3.33, 4.67]},
            {:x => 3, :y => 3, :value => 1, :xLabel => [4.67, 6.0], :yLabel => [4.67, 6.0]}
        ]
      end
    end
  end
end

shared_examples 'a histogram visualization' do
  # dataset, data_source_account

  let(:visualization) do
    Visualization::Histogram.new(dataset, {
        :bins => 2,
        :x_axis => 'column1',
        :filters => filters
    })
  end

  context '#fetch' do
    before do
      set_current_user users(:default)
      visualization.fetch!(data_source_account, 12345)
    end

    context 'with no filter' do
      let(:filters) { nil }

      it 'returns the frequency data' do
        visualization.rows.should == [
            {:bin => [0, 0.5], :frequency => 3},
            {:bin => [0.5, 1.0], :frequency => 6}
        ]
      end
    end

    context 'with filters' do
      let(:filters) { [%("#{dataset.name}"."category" = 'papaya')] }

      it 'returns the frequency data based on the filtered dataset' do
        visualization.rows.should == [
            {:bin => [0, 0.5], :frequency => 1},
            {:bin => [0.5, 1.0], :frequency => 3}
        ]
      end
    end
  end
end

shared_examples 'a frequency visualization' do
  # dataset, data_source_account

  let(:visualization) do
    Visualization::Frequency.new(dataset, {
        :bins => 2,
        :y_axis => 'category',
        :filters => filters
    })
  end

  context '#fetch' do
    before do
      set_current_user users(:default)
      visualization.fetch!(data_source_account, 12345)
    end

    context 'with no filter' do
      let(:filters) { nil }

      it 'returns the frequency data' do
        visualization.rows.should == [
            {:count => 4, :bucket => 'papaya'},
            {:count => 3, :bucket => 'orange'}
        ]
      end
    end

    context 'with filters' do
      let(:filters) { [%("#{dataset.name}"."column1" > 0), %("#{dataset.name}"."column2" < 5)] }

      it 'returns the frequency data based on the filtered dataset' do
        visualization.rows.should == [
            {:count => 2, :bucket => 'orange'},
            {:count => 1, :bucket => 'apple'}
        ]
      end
    end

  end
end

shared_examples 'a boxplot visualization' do

  let(:visualization) do
    Visualization::Boxplot.new(dataset, {
        :x_axis => x_axis,
        :y_axis => y_axis,
        :bins => bucket_count,
        :filters => filters
    })
  end

  let(:bucket_count) { 20 }
  let(:x_axis) { 'category' }
  let(:y_axis) { 'column2' }
  let(:filters) { nil }

  describe '#fetch' do
    before do
      set_current_user users(:default)
    end

    it 'returns the boxplot data' do
      visualization.fetch!(data_source_account, 12345)
      visualization.rows.should == [
          {:bucket => 'papaya', :min => 5.0, :median => 6.5, :max => 8.0, :first_quartile => 5.5, :third_quartile => 7.5, :percentage => '44.44%', :count => 4},
          {:bucket => 'orange', :min => 2.0, :median => 3.0, :max => 4.0, :first_quartile => 2.5, :third_quartile => 3.5, :percentage => '33.33%', :count => 3},
          {:bucket => 'apple', :min => 0.0, :median => 0.5, :max => 1.0, :first_quartile => 0.25, :third_quartile => 0.75, :percentage => '22.22%', :count => 2}
      ]
    end

    it 'limits the number of buckets in the boxplot summary' do
      mock(BoxplotSummary).summarize(anything, bucket_count)
      visualization.fetch!(data_source_account, 12345)
    end

    context 'with filters' do
      let(:filters) { [%("category" <> 'apple')] }

      it 'returns the boxplot data based on the filtered dataset' do
        visualization.fetch!(data_source_account, 12345)
        visualization.rows.should == [
            {:bucket => 'papaya', :min => 5.0, :median => 6.5, :max => 8.0, :first_quartile => 5.5, :third_quartile => 7.5, :percentage => '57.14%', :count => 4},
            {:bucket => 'orange', :min => 2.0, :median => 3.0, :max => 4.0, :first_quartile => 2.5, :third_quartile => 3.5, :percentage => '42.86%', :count => 3}
        ]
      end
    end

    context 'with allcaps column names' do
      let(:dataset) { all_caps_column_dataset }
      let(:filters) { nil }
      let(:x_axis) { 'KITKAT' }
      let(:y_axis) { 'STUFF' }

      it 'fetches the rows correctly' do
        visualization.fetch!(data_source_account, 12345)
        visualization.rows.should_not be_nil
      end
    end

    context 'with null values' do
      let(:dataset) { table_with_nulls }
      let(:filters) { [%("category" <> 'banana')] }
      let(:x_axis) { 'category' }
      let(:y_axis) { 'some_nulls' }

      it 'does not count the nulls in the boxplot data' do
        visualization.fetch!(data_source_account, 12345)
        visualization.rows.should =~ [
            {:bucket => 'orange', :min => 1.0, :median => 2.5, :max => 7.0, :first_quartile => 1.5, :third_quartile => 5.0, :percentage => '57.14%', :count => 4},
            {:bucket => 'apple', :min =>5.0, :median => 7.0, :max => 14.0, :first_quartile => 6.0, :third_quartile => 10.5, :percentage => '42.86%', :count => 3}
        ]
      end

      context 'with all null values' do
        let(:y_axis) { 'all_nulls' }

        it 'returns an empty set of rows' do
          visualization.fetch!(data_source_account, 12345)
          visualization.rows.should =~ []
        end
      end
    end

    context 'when the category and the value are the same column' do
      let(:x_axis) { 'column1' }
      let(:y_axis) { 'column1' }

      it 'raises an exception' do
        expect {
          visualization.fetch!(data_source_account, 12345)
        }.to raise_error
      end
    end
  end
end

shared_examples 'a timeseries visualization' do
  # dataset, data_source_account

  let(:default_filters) {
    [
        %Q{"#{dataset.name}"."time_value" > '2012-03-03'},
        %Q{"#{dataset.name}"."column1" < 5}
    ]
  }

  let(:visualization) do
    Visualization::Timeseries.new(dataset, {
        :time_interval => 'month',
        :aggregation => 'sum',
        :x_axis => 'time_value',
        :y_axis => 'column1',
        :filters => defined?(filters) ? filters : default_filters
    })
  end

  before do
    set_current_user users(:default)
  end

  describe '#fetch' do
    before do
      visualization.fetch!(data_source_account, 12345)
    end

    context 'with no filter' do
      let(:filters) { nil }

      it 'returns the timeseries data' do
        visualization.rows.should == [
            {:value => 3, :time => '2012-03'},
            {:value => 2, :time => '2012-04'},
            {:value => 1, :time => '2012-05'}
        ]
      end
    end

    context 'with filters' do
      it 'returns the timeseries data based on the filtered dataset' do
        visualization.rows.should == [
            {:value => 2, :time => '2012-03'},
            {:value => 2, :time => '2012-04'},
            {:value => 1, :time => '2012-05'}
        ]
      end
    end
  end
end
