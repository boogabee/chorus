require 'spec_helper'

describe GpdbSchemaPresenter, :type => :view do
  before do
    set_current_user users(:owner)
  end

  let(:schema) { FactoryGirl.create(:gpdb_schema, :refreshed_at => Time.now) }
  let(:presenter) { GpdbSchemaPresenter.new(schema, view) }
  let(:hash) { presenter.to_hash }

  describe '#to_hash' do
    it 'includes the fields' do
      hash[:id].should == schema.id
      hash[:name].should == schema.name
      hash[:has_credentials].should == false
      hash[:is_deleted].should == schema.deleted?
      hash[:refreshed_at].should == schema.refreshed_at
      hash[:dataset_count].should == schema.active_tables_and_views.count
      hash[:database][:id].should == schema.database.id
      hash[:database][:data_source][:id].should == schema.data_source.id
      hash[:database][:data_source][:name].should == schema.data_source.name
    end

    it "uses the cached counters for the dataset count" do
      expect {
        Schema.increment_counter(:active_tables_and_views_count, schema.id)
        schema.reload
      }.to change{presenter.to_hash[:dataset_count]}.by(1)
    end
  end
end
