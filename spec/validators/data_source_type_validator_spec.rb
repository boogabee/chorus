require 'spec_helper'

class DataSourceValidatable
  include ActiveModel::Validations
  validates_with DataSourceTypeValidator
  attr_accessor :license_type, :data_source_type
end

describe DataSourceTypeValidator do
  let(:data_source) { DataSourceValidatable.new }

  context 'when license does not limit data source types' do
    before do
      stub(License.instance).limit_data_source_types? { false }
    end

    it 'validates' do
      data_source.should be_valid
    end
  end

  context '#existing_types' do
    it 'returns a unique array of license_type for all data sources' do
      result = DataSourceTypeValidator.new({}).send(:existing_types)
      expected = [DataSource, HdfsDataSource, GnipDataSource].map(&:all).flatten.map(&:license_type).uniq
      result.should =~ expected
    end
  end

  context 'when license limits data source types' do
    let(:current_types) { current_sources.map(&:license_type) }
    before do
      stub(License.instance).limit_data_source_types? { true }
      any_instance_of(DataSourceTypeValidator) do |validator|
        stub(validator).existing_types { current_types }
      end
    end

    context 'when creating the first data source' do
      let(:current_sources) { [] }

      it 'validates' do
        data_source.should be_valid
      end
    end

    context 'when creating a second data source' do
      let(:gpdb) { data_sources(:default) }
      let(:current_sources) { [gpdb] }
      before do
        stub(data_source).new_record? { true }
      end

      context 'when creating a data source of the same type' do
        before do
          mock(data_source).license_type { gpdb.license_type }
        end

        it 'validates' do
          data_source.should be_valid
        end
      end

      context 'when creating a data source of a different type' do
        before do
          mock(data_source).license_type { 'not_the_same' }
        end

        it 'does not validate' do
          data_source.should_not be_valid
          data_source.should have_error_on(:data_source_type)
        end
      end
    end

    context 'editing the first data source' do
      let(:hadoop) { hdfs_data_sources(:hadoop) }
      let(:current_types) { [hadoop.license_type + 'different'] }
      before do
        mock(hadoop).new_record?.at_least(1) { false }
        any_instance_of(DataSourceTypeValidator) do |validator|
          stub(validator).existing_types { current_types }
          stub(validator).total_sources { 1 }
        end
      end

      it 'validates' do
        hadoop.should be_valid
      end
    end

    context 'editing 1 of multiple data sources' do
      let(:hadoop) { hdfs_data_sources(:hadoop) }
      let(:current_types) { [hadoop.license_type + 'different'] }
      before do
        mock(hadoop).new_record?.at_least(1) { false }
        any_instance_of(DataSourceTypeValidator) do |validator|
          stub(validator).existing_types { current_types }
          stub(validator).total_sources { 2 }
        end
      end

      it 'does not validate' do
        hadoop.should_not be_valid
      end
    end
  end
end
