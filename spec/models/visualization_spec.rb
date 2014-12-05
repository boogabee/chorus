require 'spec_helper'

describe Visualization do
  let(:table) { FactoryGirl.build_stubbed(:gpdb_table) }

  describe '.build' do
    shared_examples 'a visualization factory' do |type, klass|
      context "#{type} visualization" do
        let(:params) { {:type => type} }

        it "builds a #{type} visualization" do
          visualization = described_class.build(table, params)
          visualization.should be_a_kind_of(klass)
        end
      end
    end

    it_behaves_like 'a visualization factory', 'frequency', Visualization::Frequency
    it_behaves_like 'a visualization factory', 'histogram', Visualization::Histogram
    it_behaves_like 'a visualization factory', 'timeseries', Visualization::Timeseries
    it_behaves_like 'a visualization factory', 'boxplot', Visualization::Boxplot
    it_behaves_like 'a visualization factory', 'heatmap', Visualization::Heatmap

    it 'raises if an unknown type is passed' do
      expect {
        described_class.build(table, {:type => 'missing'})
      }.to raise_error(Visualization::UnknownType)
    end
  end
end
