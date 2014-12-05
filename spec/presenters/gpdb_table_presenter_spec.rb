require 'spec_helper'

describe GpdbTablePresenter, :type => :view do
  let(:table) { datasets(:table) }
  let(:presenter) { GpdbTablePresenter.new(table, view) }

  before(:each) do
    set_current_user(users(:admin))
  end

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    it "sets the object type to TABLE" do
      hash[:object_type].should == "TABLE"
    end
  end

  it_behaves_like "dataset presenter", :gpdb_table
  it_behaves_like "dataset presenter with workspace", :gpdb_table
end
