require 'spec_helper'

describe PgDatabasePresenter, :type => :view do

  describe '#to_hash' do
    let(:data_source) { data_sources(:postgres) }
    let(:db) { databases(:pg) }
    before do
      @hash = PgDatabasePresenter.new(db, view).to_hash
    end

    it 'includes the fields' do
      @hash[:name].should == db.name
      @hash[:id].should == db.id
      @hash[:data_source][:id].should == data_source.id
    end
  end
end
