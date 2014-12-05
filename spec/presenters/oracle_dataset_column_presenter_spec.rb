require "spec_helper"

describe OracleDatasetColumnPresenter, :type => :view do
  let(:column) { OracleDatasetColumn.new(:name => "column1", :data_type => type_string, :description => 'nothing') }
  let(:type_string) { "int" }

  subject { described_class.new(column, view) }

  describe "#to_hash" do
    it "includes the column's basic information" do
      hash = subject.to_hash
      hash[:name].should == "column1"
      hash[:type_category].should == "WHOLE_NUMBER"
      hash[:description].should == "nothing"
      hash[:data_type].should == "int"
      hash[:statistics].should == {}
    end
  end

  its(:statistics) { should == { } }
end
