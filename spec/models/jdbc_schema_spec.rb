require 'spec_helper'

describe JdbcSchema do
  it_behaves_like 'a subclass of schema' do
    let(:schema) { schemas(:jdbc) }
    let(:table_factory) { :jdbc_table }
    let(:view_factory) { :jdbc_view }
  end

  describe '#data_source' do
    let(:schema) {
      JdbcSchema.create!(:name => 'test_schema', :data_source => data_sources(:jdbc))
    }

    it 'returns the schemas parent' do
      schema.reload.data_source.should == data_sources(:jdbc)
    end
  end

  describe 'validations' do
    let(:schema) { JdbcSchema.new(:name => 'test_schema', :data_source => data_sources(:jdbc)) }

    it 'requires there is a data source' do
      schema.data_source = nil
      schema.valid?.should be_false
      schema.errors_on(:data_source).should include(:blank)
    end

    it 'requires a name' do
      schema.name = nil
      schema.valid?.should be_false
      schema.errors_on(:name).should include(:blank)
    end

    it 'requires a unique name per data source' do
      schema.save!
      new_schema = JdbcSchema.new(:name=> 'test_schema', :data_source => data_sources(:jdbc))
      new_schema.valid?.should be_false
      new_schema.errors_on(:name).should include(:taken)

      new_schema.data_source = FactoryGirl.build(:jdbc_data_source)
      new_schema.valid?.should be_true
    end

  end

  describe '#class_for_type' do
    let(:schema) { schemas(:jdbc) }
    it 'should return JdbcTable and JdbcView correctly' do
      schema.class_for_type('t').should == JdbcTable
      schema.class_for_type('v').should == JdbcView
    end
  end

  describe '.destroy_schemas' do
    it 'destroys schemas for given data source id' do
      data_source = data_sources(:jdbc)
      data_source.destroy
      schemas = data_source.schemas
      schemas.should_not be_empty

      JdbcSchema.destroy_schemas(data_source.id)
      schemas.reload.should be_empty
    end
  end
end
