require 'spec_helper'

describe JdbcDatasetColumnPresenter, :type => :view do
  let(:column) { JdbcDatasetColumn.new(:name => 'column1', :data_type => type_string, :description => 'nothing') }
  let(:type_string) { 'integer' }

  subject { described_class.new(column, view) }

  describe '#to_hash' do
    let(:hash) { subject.to_hash }

    it "includes the column's basic information" do
      hash[:name].should == 'column1'
      hash[:type_category].should == 'WHOLE_NUMBER'
      hash[:description].should == 'nothing'
      hash[:data_type].should == type_string
      hash[:statistics].should == {}
    end
  end

  its(:statistics) { should == { } }
end
