require 'spec_helper'

describe TypeAheadSearchPresenter, :type => :view do

  let(:user) { users(:owner) }

  before do
    index_solr_fixtures_once
    set_current_user(user)
  end

  describe '#to_hash' do
    let(:search) do
      TypeAheadSearch.new(user,
                          :query => 'typeahead', :per_page => 20).tap do |search|
        record_with_vcr do
          search.search
        end
      end
    end
    let(:presenter) { Presenter.present(search, view) }

    it 'returns an array of models including one of each type' do
      results = presenter.to_hash[:type_ahead][:results]
      types = results.map { |result| result[:entity_type] }
      types.should include('user', 'workfile', 'dataset', 'hdfs_file', 'gpdb_data_source',
                           'hdfs_data_source', 'workspace', 'jdbc_data_source', 'pg_data_source')
    end
  end
end
