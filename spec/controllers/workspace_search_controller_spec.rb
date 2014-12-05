require 'spec_helper'

describe WorkspaceSearchController do
  describe "#show" do
    let(:user) { users(:owner) }
    let(:workspace) { workspaces(:search_public) }

    before do
      log_in user
    end

    it_behaves_like "an action that requires authentication", :get, :show, :workspace_id => '-1'

    it "uses authorization" do
      mock(WorkspaceSearch).new(user, anything) do |user, params|
      end

      mock(subject).authorize! :show, workspace
      get :show, :query => 'marty', :workspace_id => workspace.id
    end

    it "uses the workspace search object" do
      fake_search = Object.new
      mock(WorkspaceSearch).new(user, anything) do |user, params|
        params[:query].should == "marty"
        params[:workspace_id].should == workspace.id.to_s
        fake_search
      end
      mock_present { |model| model.should == fake_search }
      get :show, :query => 'marty', :workspace_id => workspace.id
    end

    generate_fixture "searchResultInWorkspace.json" do
      index_solr_fixtures_once

      VCR.use_cassette "workspace_search_solr_query_as_owner" do
        get :show, :query => 'searchquery', :workspace_id => workspace.id, :per_page => 50
      end
    end

    generate_fixture "searchResultInWorkspaceWithEntityTypeWorkfile.json" do
      index_solr_fixtures_once

      VCR.use_cassette "workspace_search_solr_workfiles_query_as_owner" do
        get :show, :query => 'searchquery', :entity_type => 'workfile', :workspace_id => workspace.id
      end
    end
  end

  context 'when License#limit_search? is true' do
    let(:user) { users(:owner) }
    let(:workspace) { workspaces(:search_public) }

    before do
      log_in user
      stub(License.instance).limit_search? { true }
    end

    it 'forbids #show' do
      get :show, :query => 'nope', :workspace_id => workspace.id
      response.should be_forbidden_by_license
    end
  end
end
