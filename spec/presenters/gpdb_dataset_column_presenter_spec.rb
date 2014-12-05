require "spec_helper"

describe GpdbDatasetColumnPresenter, :type => :view do
  let(:gpdb_column) { GpdbDatasetColumn.new(:name => "column1", :data_type => type_string, :description => 'nothing') }
  let(:type_string) { "smallint" }

  subject { described_class.new(gpdb_column, view) }

  describe "#to_hash" do
    it "includes the column's basic information" do
      hash = subject.to_hash
      hash[:name].should == "column1"
      hash[:type_category].should == "WHOLE_NUMBER"
      hash[:description].should == "nothing"
      hash[:data_type].should == "smallint"
      hash[:statistics].should == {}
    end
  end

  describe "statistics" do
    context "when the model does not have statistics" do
      its(:statistics) { should == { } }
    end

    context "when the model has statistics" do
      let(:statistics) { GpdbColumnStatistics.new(nil, nil, nil, nil, nil, nil, false) }

      before do
        gpdb_column.statistics = statistics
      end

      its(:statistics) { should == GpdbColumnStatisticsPresenter.new(statistics, view).presentation_hash }
    end
  end
end
