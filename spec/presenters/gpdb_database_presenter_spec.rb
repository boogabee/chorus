require 'spec_helper'

describe GpdbDatabasePresenter, :type => :view do
  before(:each) do
    database = FactoryGirl.build(:gpdb_database, name: "abc", id: 456, data_source: FactoryGirl.build(:gpdb_data_source, :id => 123))
    @presenter = GpdbDatabasePresenter.new(database, view)
  end

  describe "#to_hash" do
    before do
      @hash = @presenter.to_hash
    end

    it "includes the fields" do
      @hash[:name].should == "abc"
      @hash[:id].should == 456
      @hash[:data_source][:id].should == 123
    end
  end
end
