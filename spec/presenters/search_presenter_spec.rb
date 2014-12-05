require 'spec_helper'

describe SearchPresenter, :type => :view do

  let(:user) { users(:owner) }

  before do
    index_solr_fixtures_once
    set_current_user(user)
  end

  describe "#to_hash" do
    context "searching without workspace" do
      before do
        search = Search.new(user, :query => 'searchquery')

        VCR.use_cassette('search_solr_query_all_types_as_owner') do
          search.search
        end
        @presenter = SearchPresenter.new(search, view)
        @hash = @presenter.to_hash
      end

      it 'includes matching users' do
        @hash.should have_key(:users)
        user_hash = @hash[:users]
        user_hash.should have_key(:numFound)
        user_hash.should have_key(:results)
        user_hash[:results][0].should have_key(:highlighted_attributes)
        user_hash[:results][0][:entity_type].should == 'user'
      end

      it 'includes matching data sources' do
        @hash.should have_key(:data_sources)
        data_source_hash = @hash[:data_sources]
        data_source_hash.should have_key(:numFound)
        data_source_hash.should have_key(:results)
        data_source_types = data_source_hash[:results].map {|result| result[:entity_type]}.uniq
        data_source_types.should =~ ['gpdb_data_source', 'hdfs_data_source', 'gnip_data_source', 'jdbc_data_source']
        data_source_hash[:results].each do |result|
          result.should have_key(:highlighted_attributes)
        end
      end

      it 'includes matching workspaces' do
        @hash.should have_key(:workspaces)
        workspaces_hash = @hash[:workspaces]
        workspaces_hash.should have_key(:numFound)
        workspaces_hash.should have_key(:results)
        workspaces_hash[:results][0].should have_key(:highlighted_attributes)
        workspaces_hash[:results][0][:entity_type].should == 'workspace'
      end

      it 'includes matching workfiles' do
        @hash.should have_key(:workfiles)
        workfile_hash = @hash[:workfiles]
        workfile_hash.should have_key(:numFound)
        workfile_hash.should have_key(:results)
        workfile_hash[:results][0].should have_key(:highlighted_attributes)
        workfile_hash[:results][0].should have_key(:version_info)
        workfile_hash[:results].each { |wf| %w(workfile linked_tableau_workfile).should include(wf[:entity_type]) }
      end

      it 'includes matching notes' do
        data_source_hash = @hash[:data_sources]
        data_source_result = data_source_hash[:results][0]
        data_source_result.should have_key(:comments)
        data_source_result[:comments].length.should == 1
        data_source_result[:comments][0][:highlighted_attributes][:body][0].should == "i love <em>searchquery</em>"
      end

      it 'includes matching datasets' do
        dataset = datasets(:searchquery_table)

        @hash.should have_key(:datasets)
        datasets_hash = @hash[:datasets]
        datasets_hash.should have_key(:numFound)
        datasets_hash.should have_key(:results)

        table_hash = datasets_hash[:results].select { |hash| hash[:object_name] == dataset.name }.first
        table_hash.should have_key(:highlighted_attributes)
        table_hash[:highlighted_attributes].should have_key(:object_name)

        table_hash[:columns][0].should have_key(:highlighted_attributes)
        table_hash[:columns][0][:highlighted_attributes].should have_key(:body)
        table_hash[:columns].size.should == 2

        table_hash[:column_descriptions][0][:highlighted_attributes].should have_key(:body)
        table_hash[:column_descriptions].size.should == 2
        table_hash[:table_description][0][:highlighted_attributes].should have_key(:body)

        table_hash[:entity_type].should == 'dataset'
      end

      it 'includes matching hdfs entries' do
        @hash.should have_key(:hdfs_entries)
        hdfs_hash = @hash[:hdfs_entries]
        hdfs_hash.should have_key(:numFound)
        hdfs_hash.should have_key(:results)
        first_result = hdfs_hash[:results][0]
        first_result.should have_key(:path)
        first_result.should have_key(:name)
        first_result.should have_key(:ancestors)
        first_result.should have_key(:highlighted_attributes)
        first_result[:entity_type].should == 'hdfs_file'
      end

      it 'includes other matching files (just attachments on notes for now)' do
        @hash.should have_key(:other_files)
        other_files_hash = @hash[:other_files]
        other_files_hash.should have_key(:numFound)
        other_files_hash.should have_key(:results)
        other_files_hash[:results][0][:highlighted_attributes].should have_key(:name)
        other_files_hash[:results][0][:entity_type].should == 'attachment'
      end

      it 'does not include workspace-specific results' do
        @hash.should_not have_key(:this_workspace)
      end
    end

    context 'when the search is restricted to a workspace' do
      let(:workspace) { workspaces(:search_public) }

      before do
        search = Search.new(user, :query => 'searchquery', :workspace_id => workspace.id)

        VCR.use_cassette('search_solr_query_all_types_with_workspace_as_owner') do
          search.models
        end
        @presenter = SearchPresenter.new(search, view)
        @hash = @presenter.to_hash
      end

      it 'includes matching results within that workspace' do
        @hash.should have_key(:this_workspace)
        this_workspace_hash = @hash[:this_workspace]
        this_workspace_hash.should have_key(:numFound)
        this_workspace_hash.should have_key(:results)
      end

      it 'highlights the schema attributes on the dataset' do
        dataset_hash = @hash[:this_workspace][:results].find { |entry| entry[:entity_type] == 'dataset' }
        dataset_hash[:schema][:highlighted_attributes][:name][0].should == "<em>searchquery</em>_schema"
        dataset_hash[:schema][:database][:highlighted_attributes][:name][0].should == "<em>searchquery</em>_database"
        dataset_hash.should have_key(:workspace)
      end
    end
  end
end
