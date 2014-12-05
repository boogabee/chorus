require "spec_helper"
describe WorkspaceSearch do
  let(:owner) { users(:owner) }

  context "with solr disabled" do
    describe "valid" do
      it "is not valid without a workspace_id" do
        search = WorkspaceSearch.new(owner, :query => 'fries')
        search.should_not be_valid
      end
    end

    describe "search" do
      before do
        any_instance_of(Sunspot::Search::AbstractSearch) do |search|
          stub(search).group_response { {} }
        end
      end

      context "when unscoped" do
        let(:search) { WorkspaceSearch.new(owner, :query => 'bob', :workspace_id => 7) }

        it "searches only for Workspace, Workfiles and Datasets (and Notes)" do
          search.results
          Sunspot.session.should be_a_search_for(Workspace)
          Sunspot.session.should be_a_search_for(Workfile)
          Sunspot.session.should be_a_search_for(Dataset)
          Sunspot.session.should be_a_search_for(Events::Note)
          Sunspot.session.should_not be_a_search_for(User)
        end

        it "scopes the search to the workspace" do
          search.results
          Sunspot.session.should have_search_params(:with) {
            any_of do
              with :workspace_id, 7
              with :found_in_workspace_id, 7
            end
          }
        end

        it "should not facet by type_name" do
          search.results
          Sunspot.session.should_not have_search_params(:facet, :type_name)
        end

        context "when scoped to a invalid entity type" do
          let(:search) { WorkspaceSearch.new(owner, :query => 'bob', :workspace_id => 7, :entity_type => 'user') }

          it "raises validation error" do
            expect {
              search.results
            }.to raise_error(ApiValidationError)
          end
        end
      end

      context "when scoped to an entity_type" do
        let(:search) { WorkspaceSearch.new(owner, :query => 'bob', :workspace_id => 7, :entity_type => 'workfile') }

        it "scopes the search to the type" do
          search.results
          Sunspot.session.should be_a_search_for(Workfile)
          Sunspot.session.should be_a_search_for(Events::Note)
          Sunspot.session.should_not be_a_search_for(Workspace)
          Sunspot.session.should_not be_a_search_for(Dataset)
          Sunspot.session.should_not be_a_search_for(User)
        end
      end
    end
  end

  context "with solr enabled" do
    let(:workspace) { workspaces(:search_public) }
    let(:workfile) { workfiles(:search_public) }
    let(:matching_table) { datasets(:searchquery_table) }
    let(:matching_view) { datasets(:searchquery_chorus_view) }
    let(:typeahead_dataset) { datasets(:typeahead_gpdb_table) }
    let(:hdfs_dataset) { datasets(:searchquery_hadoop) }
    before do
      index_solr_fixtures_once
    end

    describe "num_found" do
      it "returns the total number of results found" do
        VCR.use_cassette('workspace_search_solr_query_as_owner') do
          search = WorkspaceSearch.new(owner, :query => 'searchquery', :workspace_id => workspace.id)
          search.num_found.should == 9
        end
      end
    end

    describe "results" do
      it "returns the founds results" do
        VCR.use_cassette('workspace_search_solr_query_as_owner') do
          search = WorkspaceSearch.new(owner, :query => 'searchquery', :workspace_id => workspace.id)
          search.results.should =~ [
            workfile, matching_table, matching_view, workspace, typeahead_dataset, hdfs_dataset,
            datasets(:typeahead_chorus_view), datasets(:searchquery_chorus_view_private), datasets(:searchable_tag)
          ]
        end
      end

      it "has highlighted results" do
        VCR.use_cassette('workspace_search_solr_query_as_owner') do
          search = WorkspaceSearch.new(owner, :query => 'searchquery', :workspace_id => workspace.id)
          search_result_workfile = search.results.find { |m| m == workfile }
          search_result_workfile.highlighted_attributes[:description][0].should == '<em>searchquery</em>'
        end
      end
    end
  end
end