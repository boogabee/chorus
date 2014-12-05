require 'spec_helper'

def it_validates_duplicate(new_model, existing_model)
  it "returns false if a #{new_model.to_s.classify} is invalid" do
    FactoryGirl.create(new_model, :name => 'awesome_duplicate_name')
    FactoryGirl.build(existing_model, :name => 'awesome_duplicate_name').save(:validate => false)

    ExistingDataSourcesValidator.run(data_source_classes).should be_false
  end
end

describe ExistingDataSourcesValidator do
  before do
    stub(ExistingDataSourcesValidator).log
  end

  describe '.run' do
    let(:data_source_classes) { [DataSource, HdfsDataSource, GnipDataSource] }

    it "returns true if the data sources are all valid" do
      ExistingDataSourcesValidator.run(data_source_classes).should be_true
    end

    it_validates_duplicate(:gpdb_data_source, :gnip_data_source)
    it_validates_duplicate(:hdfs_data_source, :gpdb_data_source)
    it_validates_duplicate(:gnip_data_source, :gnip_data_source)

    it "returns true if there is a deleted_model with the same name" do
      FactoryGirl.create(:gpdb_data_source, :name => 'duplicate_deleted_name').destroy
      FactoryGirl.create(:gpdb_data_source, :name => 'duplicate_deleted_name')
      ExistingDataSourcesValidator.run([DataSource]).should be_true
    end

    it "doesn't validate tables that don't exist" do
      klass = Class.new(ActiveRecord::Base) do
        table_name = 'non_existent_records'
      end

      ExistingDataSourcesValidator.run([klass]).should be_true
    end

    it 'works even if one of the types no longer exists in the codebase' do
      data_source = data_sources(:oracle)
      data_source.update_attributes!(type: 'LolType')

      ExistingDataSourcesValidator.run([DataSource]).should be_true
    end
  end
end
