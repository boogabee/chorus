require 'spec_helper'

describe GpdbViewPresenter, :type => :view do
  before(:each) do
    set_current_user(users(:admin))

    gpdb_data_source = FactoryGirl.build(:gpdb_data_source, :id => 123, :name => "data_source1")
    database = FactoryGirl.build(:gpdb_database, :id => 789, :name => "db1", :data_source => gpdb_data_source)
    schema = FactoryGirl.build(:gpdb_schema, :id => 456, :name => "abc", :database => database)
    db_view = FactoryGirl.build(:gpdb_view, :id => 321, :name => "view1", :schema => schema)

    @presenter = GpdbViewPresenter.new(db_view, view)
  end

  describe "#to_hash" do
    let(:hash) { @presenter.to_hash }

    it 'has the right object type' do
      hash[:object_type].should == 'VIEW'
    end
  end

  it_behaves_like "dataset presenter", :gpdb_view
  it_behaves_like "dataset presenter with workspace", :gpdb_view
end
