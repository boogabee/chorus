require 'spec_helper'

describe OracleTable do
  describe "#verify_in_source" do
    let(:table) { datasets(:oracle_table) }
    let(:user) { users(:owner) }
    let(:connection) { Object.new }

    before do
      stub(table.schema).connect_as(user) { connection }
      stub(table.schema.parent).connect_as(user) { connection }
    end

    it "calls table_exists? and schema_exists? on the oracle database connection" do
      mock(connection).table_exists?(table.name) { "duck" }
      mock(connection).schema_exists?(table.schema.name) { "quack" }
      table.verify_in_source(user).should == "duck"
    end
  end
end