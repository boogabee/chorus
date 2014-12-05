require 'spec_helper'

describe DatasetColumnPresenter, type: :view do
  let(:column) { OpenStruct.new(name: 'column1', data_type: type_string, description: 'nothing') }
  let(:type_string) { 'SMALLINT' }

  subject {
    DatasetColumnPresenter.new(column, view)
  }

  describe '#to_hash' do
    it 'includes the columns basic information' do
      mock(subject).type_category { 'bar' }
      hash = subject.to_hash
      hash[:name].should == 'column1'
      hash[:type_category].should == 'bar'
      hash[:description].should == 'nothing'
      hash[:data_type].should == 'smallint'
      hash[:statistics].should == {}
    end
  end

  describe 'statistics' do
    describe 'when the model does not have statistics' do
      its(:statistics) { should == { } }
    end

    describe 'when the model has statistics' do
      let(:statistics) { Object.new }
      let(:fake_presented_statistics) { Object.new }

      before do
        stub(subject).type_category { 'bar' }
        column.statistics = statistics
      end

      it 'presents the statistics' do
        mock(subject).present(statistics) { fake_presented_statistics }
        subject.to_hash[:statistics].should == fake_presented_statistics
      end
    end
  end
end
