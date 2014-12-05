require 'spec_helper'

describe OracleSqlResultPresenter, :type => :view do
  let(:result_set) { OracleSqlResult.new }
  let(:presenter) { OracleSqlResultPresenter.new(result_set, view) }

  describe "#to_hash" do
    it "formats date values to mm/dd/yyyy" do
      result_set.add_column("day", "DATE")
      result_set.add_row(["2011-12-23 00:00:00"])
      date = presenter.to_hash[:rows].first.first
      date.should eq("12/23/2011")
    end

    it "formats timestamp values to mm/dd/yyyy hh:mm:ss.SSS a" do
      result_set.add_column("time", "TIMESTAMP")
      result_set.add_row(["2002-09-10 14:10:10.123"])
      time = presenter.to_hash[:rows].first.first
      time.should eq("9/10/2002 2:10:10.123 PM")
    end
  end
end