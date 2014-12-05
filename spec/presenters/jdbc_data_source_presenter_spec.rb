require 'spec_helper'

describe JdbcDataSourcePresenter, :type => :view do

  let(:jdbc_data_source) { data_sources(:jdbc) }
  let(:user) { jdbc_data_source.owner }
  let(:options) { {} }
  let(:presenter) { JdbcDataSourcePresenter.new(jdbc_data_source, view, options) }

  let(:hash) { presenter.to_hash }

  describe '#to_hash' do
    it 'includes the right keys' do
      hash.should have_key(:id)
      hash.should have_key(:name)
      hash.should have_key(:port)
      hash.should have_key(:host)
      hash.should have_key(:description)
      hash.should have_key(:db_name)
      hash.should have_key(:version)
      hash.should have_key(:online)
      hash.should have_key(:shared)
      hash.should have_key(:owner)
      hash.should have_key(:schema_blacklist)
      hash[:entity_type].should == 'jdbc_data_source'
    end
  end

  it 'should use ownerPresenter Hash method for owner' do
    owner = hash[:owner]
    owner.to_hash.should == (UserPresenter.new(user, view).presentation_hash)
  end

  it 'should present the schema blacklist' do
    hash[:schema_blacklist].size.should > 0
    hash[:schema_blacklist].should == jdbc_data_source.connect_as_owner.schema_blacklist
  end

  it_behaves_like 'activity stream data source presenter'
  it_behaves_like :succinct_data_source_presenter
end
