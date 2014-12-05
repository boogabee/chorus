require 'spec_helper'

describe OracleViewPresenter, :type => :view do
  let(:table) { datasets(:table) }
  let(:presenter) { OracleViewPresenter.new(table, view) }

  before(:each) do
    set_current_user(users(:admin))
  end

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    it "sets the object type to VIEW" do
      hash[:object_type].should == "VIEW"
    end
  end

  it_behaves_like "oracle dataset presenter", :oracle_view
end
