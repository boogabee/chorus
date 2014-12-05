require 'spec_helper'

describe SearchController do
  def self.generate_and_record_fixture(fixture_name, &block)
    self.generate_fixture fixture_name do
      index_solr_fixtures_once

      tape_name = "search_solr_query_" + fixture_name.underscore.gsub(".json", "")
      VCR.use_cassette tape_name do
        instance_exec(&block)
      end
    end
  end

  describe "#show" do
    let(:user) { users(:owner) }

    before do
      log_in user

      any_instance_of JdbcConnection do |ds|
        # teradriver fails loudly
        stub(ds).metadata_for_dataset.with_any_args { {:column_count => 2} }
      end
    end

    it_behaves_like "an action that requires authentication", :get, :show

    it "uses the search object" do
      fake_search = Object.new
      mock(Search).new(user, anything) do |_, params|
        params[:query].should == "marty"
        fake_search
      end
      mock_present { |model| model.should == fake_search }
      get :show, :query => 'marty'
    end

    generate_and_record_fixture "searchResult.json" do
      get :show, :query => 'searchquery'
    end

    generate_and_record_fixture "tagSearchResult.json" do
      get :show, :query => 'alpha', :tag => true
    end

    generate_and_record_fixture "emptySearchResult.json" do
      #Sunspot.session = Sunspot.session.original_session
      get :show, :query => 'hippopotomous'
    end

    generate_and_record_fixture "searchResultWithEntityTypeUser.json" do
      get :show, :query => 'searchquery', :entity_type => 'user'
    end

    generate_and_record_fixture "searchResultWithAttachmentOnDataSourceNote.json" do
      get :show, :query => 'searchquery_data_source'
    end

    generate_and_record_fixture "searchResultWithAttachmentOnWorkspaceNote.json" do
      get :show, :query => 'searchquery_workspace'
    end

    generate_and_record_fixture "searchResultWithAttachmentOnWorkfileNote.json" do
      get :show, :query => 'searchquery_workfile'
    end

    generate_and_record_fixture "searchResultWithAttachmentOnDatasetNote.json" do
      get :show, :query => 'searchquery_dataset'
    end

    generate_and_record_fixture "searchResultWithAttachmentOnHadoopNote.json" do
      get :show, :query => 'searchquery_hadoop'
    end

    generate_and_record_fixture "searchResultWithAttachmentOnHdfsNote.json" do
      get :show, :query => 'searchquery_hdfs_file'
    end

    generate_and_record_fixture "searchResultWithAttachmentOnWorkspaceDatasetNote.json" do
      get :show, :query => 'searchquery_workspace_dataset'
    end
  end

  describe "#workspaces" do
    let(:user) { users(:no_collaborators) }
    let(:search_object) { Object.new }

    it_behaves_like "an action that requires authentication", :get, :workspaces

    context "when logged in" do
      before do
        log_in user
      end

      it "should search within the users workspaces and present the results" do
        stub(MyWorkspacesSearch).new(user, hash_including(:query => 'searchything')) { search_object }
        mock(@controller).present(search_object, :presenter_options => {:presenter_class => 'SearchPresenter'}) { @controller.render :json => {} }
        get :workspaces, :query => 'searchything'
      end
    end
  end

  describe "#type_ahead" do
    it_behaves_like "an action that requires authentication", :get, :type_ahead

    context "with a user" do
      let(:user) { users(:owner) }
      before { log_in user }

      it "uses the search object" do
        fake_search = Object.new
        mock(TypeAheadSearch).new(user, anything) do |_, params|
          params[:query].should == "marty"
          fake_search
        end
        mock_present { |model| model.should == fake_search }
        get :type_ahead, :query => 'marty'
      end

      generate_and_record_fixture "typeAheadSearchResult.json" do
        get :type_ahead, :query => 'typeahead', :per_page => 20
      end
    end
  end

  describe "#reindex" do
    it_behaves_like "an action that requires authentication", :post, :reindex

    context "not admin" do
      before do
        log_in users(:no_collaborators)
      end

      it "should refuse" do
        post :reindex
        response.code.should == "403"
      end
    end

    context "as admin" do
      before do
        log_in users(:admin)
      end

      it "should enqueue the refresh" do
        mock(QC.default_queue).enqueue_if_not_queued("SolrIndexer.refresh_and_reindex", ['Dataset', 'GpdbDataSource'])
        post :reindex, :types => ['Dataset', 'GpdbDataSource']
        response.should be_success
      end

      it "should allow refresh of all searchable types" do
        mock(QC.default_queue).enqueue_if_not_queued("SolrIndexer.refresh_and_reindex", 'all')
        post :reindex
        response.should be_success
      end
    end
  end

  context 'when License#limit_search? is true' do
    let(:user) { users(:owner) }
    before do
      log_in user
      stub(License.instance).limit_search? { true }
    end

    it 'forbids #show' do
      get :show, :query => 'nope'
      response.should be_forbidden_by_license
    end

    it 'forbids #workspaces' do
      get :workspaces, :query => 'nope'
      response.should be_forbidden_by_license
    end

    it 'allows #typeahead' do
      fake_search = Object.new
      mock(TypeAheadSearch).new(user, anything) do |_, params|
        params[:query].should == 'marty'
        fake_search
      end
      mock_present { |model| model.should == fake_search }
      get :type_ahead, :query => 'marty'
      response.code.should == '200'
    end
  end
end
