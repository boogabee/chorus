require 'spec_helper'

describe OracleView do
  describe "#verify_in_source" do
    let(:view) { datasets(:oracle_view) }
    let(:user) { users(:owner) }
    let(:connection) { Object.new }

    it "calls view_exists? on the oracle database connection" do
      stub(view.schema).verify_in_source(user) { true }
      stub(view.schema).connect_as(user) { connection }


      mock(connection).view_exists?(view.name) { "duck" }
      view.verify_in_source(user).should == "duck"
    end
  end
end