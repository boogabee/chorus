require 'spec_helper'

describe JdbcSchemaPresenter, :type => :view do

  let(:schema) { FactoryGirl.create(:oracle_schema) }
  let(:presenter) { OracleSchemaPresenter.new(schema, view) }
  let(:hash) { presenter.to_hash }

  before do
    #2.times { FactoryGirl.create(:oracle_table, :schema => schema) }
    #schema.active_tables_and_views_count = 2
    #schema.save!
    schema.touch :refreshed_at
  end

  describe '#to_hash' do
    it 'includes the fields' do
      hash[:id].should == schema.id
      hash[:name].should == schema.name
      hash[:dataset_count].should == 0
      hash[:is_deleted].should == schema.deleted?
      hash[:refreshed_at].should == schema.refreshed_at
      hash[:refreshed_at].should_not be_nil
      hash[:entity_type].should == schema.entity_type_name
      hash[:data_source][:id].should == schema.data_source.id
      hash[:data_source][:name].should == schema.data_source.name
    end
  end
end