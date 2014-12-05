require 'spec_helper'

describe JdbcView do
  let(:view) { datasets(:jdbc_view) }

  describe '#verify_in_source' do
    let(:user) { users(:owner) }
    let(:connection) { Object.new }

    it 'calls view_exists? on the oracle database connection' do
      stub(view.schema).verify_in_source(user) { true }
      stub(view.schema).connect_as(user) { connection }


      mock(connection).view_exists?(view.name) { 'duck' }
      view.verify_in_source(user).should == 'duck'
    end
  end

  describe '#column_type' do
    it 'is JdbcDatasetColumn' do
      view.column_type.should == 'JdbcDatasetColumn'
    end
  end
end
