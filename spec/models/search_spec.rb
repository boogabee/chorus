require "spec_helper"

describe Search do
  let(:user) { users(:owner) }
  let(:add_stemmed_fields) do
    lambda do |params|
      return unless params[:qf]
      fields = params[:qf].split
      new_fields = fields.map {|field| field.sub /_texts$/, "_stemmed_texts" }
      params[:qf] = (fields + new_fields).join(" ")
    end
  end

  describe ".new" do
    it "takes current user and search params" do
      search = Search.new(user, :query => 'fries')
      search.current_user.should == user
      search.query.should == 'fries'
    end
  end

  describe "#valid" do
    it "is not valid without a valid entity_type" do
      search = Search.new(user, :query => 'fries', :entity_type => 'potato')
      search.should have_error_on(:entity_type).with_message(:invalid_entity_type)
    end

    it "raises ApiValidationError when search is invalid" do
      search = Search.new(user, :query => 'fries')
      stub(search).valid? { false }
      expect {
        search.search
      }.to raise_error(ApiValidationError)
    end
  end

  describe "#search" do
    it "searches for all types with query" do
      search = Search.new(user, :query => 'bob')
      search.search
      Sunspot.session.should be_a_search_for(User)
      Sunspot.session.should be_a_search_for(GpdbDataSource)
      Sunspot.session.should be_a_search_for(OracleDataSource)
      Sunspot.session.should be_a_search_for(HdfsDataSource)
      Sunspot.session.should be_a_search_for(GnipDataSource)
      Sunspot.session.should be_a_search_for(JdbcDataSource)
      Sunspot.session.should be_a_search_for(PgDataSource)
      Sunspot.session.should be_a_search_for(Workspace)
      Sunspot.session.should be_a_search_for(Workfile)
      Sunspot.session.should be_a_search_for(Dataset)
      Sunspot.session.should be_a_search_for(HdfsEntry)
      Sunspot.session.should be_a_search_for(Attachment)
      Sunspot.session.should be_a_search_for(Events::Note)
      Sunspot.session.should be_a_search_for(Comment)
      Sunspot.session.should have_search_params(:fulltext) {
        fulltext "bob"
        adjust_solr_params &add_stemmed_fields
      }
      Sunspot.session.should have_search_params(:facet, :type_name)
      Sunspot.session.should have_search_params(:group) {
        group :grouping_id do
          truncate
          limit 3
        end
      }
    end

    it "supports pagination" do
      search = Search.new(user, :query => 'bob', :page => 4, :per_page => 42)
      search.search
      Sunspot.session.should have_search_params(:paginate, :page => 4, :per_page => 42)
    end

    context "when limiting the number of records per type" do
      it "performs secondary searches to pull back needed records" do
        any_instance_of(Sunspot::Search::AbstractSearch) do |search|
          stub(search).group_response { {} }
        end
        search = Search.new(user, :query => 'bob', :per_type => 3)
        stub(search).num_found do
          hsh = Hash.new(0)
          hsh.merge({:users => 100, :data_sources => 100, :workspaces => 100, :workfiles => 100, :datasets => 100, :hdfs_entries => 100, :attachments => 100})
        end
        stub(search.search).each_hit_with_result { [] }
        search.models
        types_to_search = search.models_to_search.inject(ActiveSupport::OrderedHash.new) do |hash, model|
          hash[model.type_name] ||= []
          hash[model.type_name] << model
          hash
        end
        Sunspot.session.searches.length.should == types_to_search.keys.length + 1
        types_to_search.each_with_index do |type_and_model, index|
          models = type_and_model.last
          sunspot_search = Sunspot.session.searches[index+1]
          models.each do |model|
            sunspot_search.should be_a_search_for(model)
          end
          (search.models_to_search - models).each do |other_model|
            sunspot_search.should_not be_a_search_for(other_model)
          end
          sunspot_search.should have_search_params(:fulltext) {
            fulltext "bob"
            adjust_solr_params &add_stemmed_fields
          }
          sunspot_search.should have_search_params(:paginate, :page => 1, :per_page => 3)
          sunspot_search.should_not have_search_params(:facet, :type_name)
        end
      end

      it "ignores pagination" do
        search = Search.new(user, :query => 'bob', :per_type => 3, :page => 2, :per_page => 5)
        search.search
        Sunspot.session.should have_search_params(:paginate, :page => 1, :per_page => 100)
      end

      it "raises an error if solr does not work properly" do
        search = Search.new(user, :query => 'bob', :per_type => 3, :page => 2, :per_page => 5)
        stub(search).build_search {
          raise SunspotError.new("error")
        }
        expect { search.search }.to raise_error(SunspotError)
      end
    end

    context "when limiting the type of model searched" do
      it "searches only the specified model type" do
        search = Search.new(user, :query => 'bob', :entity_type => 'data_source')
        search.search
        Sunspot.session.should_not be_a_search_for(User)
        Sunspot.session.should be_a_search_for(GpdbDataSource)
        Sunspot.session.should be_a_search_for(OracleDataSource)
        Sunspot.session.should be_a_search_for(HdfsDataSource)
        Sunspot.session.should be_a_search_for(GnipDataSource)
        Sunspot.session.should be_a_search_for(JdbcDataSource)
        Sunspot.session.should be_a_search_for(PgDataSource)
      end

      it "creates a search session just for that model" do
        search = Search.new(user, :query => 'bob', :entity_type => 'user')
        search.search
        Sunspot.session.should be_a_search_for(User)
        Sunspot.session.should_not be_a_search_for(GpdbDataSource)
        Sunspot.session.should have_search_params(:fulltext) {
          fulltext "bob"
          adjust_solr_params &add_stemmed_fields
        }
        Sunspot.session.should_not have_search_params(:facet, :type_name)
      end
    end

    context "when searching datasets with no data source accounts accessible to the user" do
      it "does not include the condition for data source accounts" do
        stub(user).accessible_account_ids { [] }
        Search.new(user, :query => 'whatever', :entity_type => :dataset).search
        Sunspot.session.should have_search_params(:with) {
          any_of do
            without :security_type_name, RelationalDataset.name
          end
        }
      end
    end

    describe "search with a specific model" do
      it "only searches for that model" do
        search = Search.new(user, :query => 'bob', :entity_type => 'user')
        search.search
        session = Sunspot.session
        session.should be_a_search_for(User)
        session.should_not be_a_search_for(GpdbDataSource)
        session.should have_search_params(:fulltext) {
          fulltext "bob"
          adjust_solr_params &add_stemmed_fields
        }
        session.should_not have_search_params(:facet, :type_name)
      end
    end

    describe "with a workspace_id" do
      let(:search) { Search.new(user, :query => 'bob', :per_type => 3, :workspace_id => 7) }

      before do
        any_instance_of(Sunspot::Search::AbstractSearch) do |search|
          stub(search).group_response { {} }
        end
        search.models
      end

      it "performs a secondary search to pull back workfiles and datasets within the workspace" do
        Sunspot.session.searches.length.should == 2
        last_search = Sunspot.session.searches.last
        last_search.should be_a_search_for(Dataset)
        last_search.should be_a_search_for(Workfile)
        last_search.should be_a_search_for(Workspace)
        last_search.should_not be_a_search_for(User)
        last_search.should have_search_params(:with, :workspace_id, 7)
      end

      it "limits the results to a max of per_page" do
        Sunspot.session.searches.last.should have_search_params(:paginate, :page => 1, :per_page => 3)
      end

      it "searches for the same query" do
        Sunspot.session.searches.last.should have_search_params(:fulltext) {
          fulltext "bob"
          adjust_solr_params &add_stemmed_fields
        }
      end

      it "does not perform the workspace search more than once" do
        search.num_found
        Sunspot.session.searches.length.should == 2
      end

      context "when filtering by some entity type" do
        let(:search) { Search.new(user, :query => 'view', :workspace_id => 7, :entity_type => 'dataset') }

        it "limits the results to a specific entity_type" do
          last_search = Sunspot.session.searches.last
          last_search.should be_a_search_for(Dataset)
          last_search.should_not be_a_search_for(Workspace)
        end
      end
    end

    describe "tag search" do
      let(:tag) { Tag.find_by_name("alpha") }
      let(:params) { { :tag => true, :query => tag.name } }
      let(:search) { Search.new(user, params) }

      before do
        any_instance_of(Sunspot::Search::AbstractSearch) do |search|
          stub(search).group_response { {} }
        end
      end

      it "filters by tag_id" do
        search.models
        Sunspot.session.should have_search_params(:with, :tag_ids, tag.id)
        Sunspot.session.should_not have_search_params(:fulltext) {
          fulltext tag.name
          adjust_solr_params &add_stemmed_fields
        }
      end

      it "orders by sort_name" do
        search.models
        Sunspot.session.should have_search_params(:order_by, :sort_name)
      end

      describe "with a workspace_id" do
        let(:search) { Search.new(user, params.merge(:workspace_id => 7)) }

        it "performs a secondary search to pull back workfiles and datasets within the workspace" do
          search.models
          Sunspot.session.searches.length.should == 2
          last_search = Sunspot.session.searches.last
          last_search.should have_search_params(:with, :workspace_id, 7)
          last_search.should have_search_params(:with, :tag_ids, tag.id)
          last_search.should_not have_search_params(:fulltext) {
            fulltext tag.name
            adjust_solr_params &add_stemmed_fields
          }
        end
      end

      context "when tag does not exist" do
        let(:search) { Search.new(user, :tag => true, :query => 'i am not a tag') }

        it "returns empty results" do
          search.models.values.flatten.should be_empty
        end
      end
    end
  end

  context "with solr enabled" do
    let(:admin) { users(:admin) }
    let(:owner) { users(:owner) }
    let(:the_collaborator) { users(:the_collaborator) }
    let(:gpdb_data_source) { data_sources(:default) }
    let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }
    let(:gnip_data_source) { gnip_data_sources(:default) }
    let(:jdbc_data_source) { data_sources(:searchquery_jdbc) }
    let(:pg_data_source) { data_sources(:searchquery_pg) }
    let(:hdfs_entry) { HdfsEntry.find_by_path("/searchquery/result.txt") }
    let(:attachment) { attachments(:attachment) }
    let(:public_workspace) { workspaces(:public_with_no_collaborators) }
    let(:private_workspace) { workspaces(:private) }
    let(:private_workspace_not_a_member) { workspaces(:private_with_no_collaborators) }
    let(:private_workfile_hidden_from_owner) { workfiles(:no_collaborators_private) }
    let(:private_workfile) { workfiles(:private) }
    let(:public_workfile) { workfiles(:public) }
    let(:dataset) { datasets(:searchquery_table) }
    let(:hadoop_dataset) { datasets(:searchquery_hadoop) }
    let(:typeahead_dataset) { datasets(:typeahead_gpdb_table) }
    let(:shared_dataset) { datasets(:searchquery_shared_table) }
    let(:chorus_view) { datasets(:searchquery_chorus_view) }

    before do
      stub(DatasetColumn).columns_for.with_any_args { [] } # don't ask databases for columns in test
      index_solr_fixtures_once
    end

    def create_and_record_search(*args)
      if args.empty?
        tape_name = "search_solr_searchquery"
        args = [owner, {:query => 'searchquery'}]
      end
      record_with_vcr(tape_name) do
        search = Search.new(*args)
        yield search
      end
    end

    describe "with an empty search string" do
      it "returns an empty array" do
        create_and_record_search(owner, :query => "") do |search|
          search.models.should be {}
          search.num_found.values.should == []
        end
      end
    end

    describe "when the search string is a single special character" do
      %w{+ -}.each do | character |
        it "returns empty results for strings that are just '#{character}'" do
          create_and_record_search owner, {:query => character } do |search|
            search.models.should be {}
            search.num_found.values.should == []
          end
        end
      end
    end

    describe "num_found" do
      it "returns a hash with the number found of each type" do
        create_and_record_search do |search|
          search.num_found[:users].should == 1
          search.num_found[:data_sources].should == 5
          search.num_found[:datasets].should == 8
        end
      end

      it "returns a hash with the total count for the given type" do
        create_and_record_search(owner, :query => 'searchquery', :entity_type => 'user') do |search|
          search.num_found[:users].should == 1
          search.num_found[:data_sources].should == 0
        end
      end

      it "includes the number of workspace specific results found" do
        workspace = workspaces(:search_public)
        create_and_record_search(owner, :query => 'searchquery', :workspace_id => workspace.id) do |search|
          search.num_found[:this_workspace].should == 9
        end
      end
    end

    describe "users" do
      it "includes the highlighted attributes" do
        create_and_record_search do |search|
          user = search.users.first
          user.highlighted_attributes[:first_name][0].should == '<em>searchquery</em>'
        end
      end

      it "returns the User objects found" do
        create_and_record_search do |search|
          search.users.length.should == 1
          search.users.first.should == owner
        end
      end
    end

    describe "data_sources" do
      it "should include Gpdb, Hadoop, Jdbc, and Gnip" do
        create_and_record_search do |search|
          search.data_sources.should include(gpdb_data_source)
          search.data_sources.should include(hdfs_data_source)
          search.data_sources.should include(gnip_data_source)
          search.data_sources.should include(jdbc_data_source)
        end
      end

      context "including highlighted attributes" do
        [GpdbDataSource, HdfsDataSource, GnipDataSource, JdbcDataSource, PgDataSource].each do |data_source_type|
          it "should include highlighted attributes for #{data_source_type.name}" do
            create_and_record_search do |search|
              data_source = search.data_sources.select { |data_source| data_source.is_a?(data_source_type) }.first
              data_source.highlighted_attributes.length.should > 0
              data_source.highlighted_attributes[:description][0].should =~ /<em>searchquery<\/em>/
            end
          end
        end
      end
    end

    describe "datasets" do
      it "includes the highlighted attributes" do
        create_and_record_search do |search|
          dataset = search.datasets.find { |dataset| dataset.name == 'searchquery_table' }
          dataset.highlighted_attributes[:name][0].should == "<em>searchquery</em>_table"
          dataset.highlighted_attributes[:database_name][0].should == "<em>searchquery</em>_database"
          dataset.highlighted_attributes[:schema_name][0].should == "<em>searchquery</em>_schema"
          dataset.highlighted_attributes.should have_key(:table_description)
          dataset.highlighted_attributes.should have_key(:column_name)
          dataset.highlighted_attributes.should have_key(:column_description)
          dataset.highlighted_attributes.length.should == 6
        end
      end

      it "includes the highlighted query for a chorus view" do
        create_and_record_search do |search|
          chorus_view = search.datasets.find { |dataset| dataset.is_a? ChorusView }
          chorus_view.highlighted_attributes[:query][0].should == "select <em>searchquery</em> from a_table"
        end
      end

      it "returns the Dataset objects found" do
        create_and_record_search do |search|
          search.datasets.should =~ [
            dataset, shared_dataset, chorus_view,
            typeahead_dataset, datasets(:typeahead_chorus_view),
            datasets(:searchquery_chorus_view_private), datasets(:searchable_tag),
            hadoop_dataset
          ]
        end
      end

      it "excludes datasets you don't have permissions to" do
        user = users(:no_collaborators)
        user.data_source_accounts.joins(:data_source_account_permissions).should be_empty
        create_and_record_search(user, :query => 'searchquery', :entity_type => :dataset) do |search|
          search.datasets.should =~ [shared_dataset, hadoop_dataset]
        end
      end

      it "includes notes" do
        events(:note_on_dataset).body.should == "notesearch ftw"
        create_and_record_search(owner, :query => 'notesearch') do |search|
          dataset = search.datasets.first
          dataset.search_result_notes[0][:highlighted_attributes][:body][0].should == "<em>notesearch</em> ftw"
        end
      end

      it "removes tags from the note body" do
        create_and_record_search(owner, :query => 'searchwithhtml') do |search|
          restore_solr_index_after [Events::Note] do
            note = events(:note_on_dataset)
            note.update_attribute(:body, 'sometext <b>searchwithhtml</b> ftw')
            Sunspot.commit
            dataset = search.datasets.first
            dataset.search_result_notes[0][:highlighted_attributes][:body][0].should match %r{sometext\s+<em>searchwithhtml</em>\s+ftw}
          end
        end
      end

      context "when the search results include note that has been deleted (i.e. the search index is stale)" do
        it "doesn't raise an error" do
          note = events(:note_on_dataset)
          note.body.should == "notesearch ftw"
          create_and_record_search(owner, :query => 'notesearch') do |search|
            expect {
              note.delete
              search.datasets
            }.to_not raise_error
          end
        end
      end

      it "includes insights" do
        events(:insight_on_dataset).body.should == "insightsearch ftw"
        create_and_record_search(owner, :query => 'insightsearch') do |search|
          dataset = search.datasets.first
          dataset.search_result_notes[0][:highlighted_attributes][:body][0].should == "<em>insightsearch</em> ftw"
          dataset.search_result_notes[0][:is_insight].should be_true
        end
      end

      it "includes comments on notes" do
        comment = comments(:comment_on_note_on_dataset)
        comment.body.should == "commentsearch ftw"
        create_and_record_search(owner, :query => 'commentsearch') do |search|
          dataset = search.datasets.find { |dataset| comment.event.target1 == dataset }
          dataset.search_result_notes[0][:highlighted_attributes][:body][0].should == "<em>commentsearch</em> ftw"
          dataset.search_result_notes[0][:is_comment].should be_true
        end
      end

      it "removes tags from the comment body" do
        create_and_record_search(owner, :query => 'searchwithhtml') do |search|
          restore_solr_index_after [Events::Note] do
            comment = comments(:comment_on_note_on_dataset)
            comment.update_attribute(:body, 'sometext <b>searchwithhtml</b> ftw')
            Sunspot.commit
            dataset = search.datasets.first
            dataset.search_result_notes[0][:highlighted_attributes][:body][0].should match %r{sometext\s+<em>searchwithhtml</em>\s+ftw}
          end
        end
      end

      it "excludes notes on datasets the user can't see" do
        events(:note_on_dataset).body.should == "notesearch ftw"
        create_and_record_search(the_collaborator, :query => 'notesearch') do |search|
          search.datasets.should be_empty
        end
      end

      it "includes notes created in the workspace context" do
        events(:note_on_workspace_dataset).body.should == "workspacedatasetnotesearch"
        create_and_record_search(owner, :query => 'workspacedatasetnotesearch') do |search|
          dataset = search.datasets.first
          dataset.search_result_notes[0][:highlighted_attributes][:body][0].should == "<em>workspacedatasetnotesearch</em>"
        end
      end
    end

    describe "chorus_views" do
      let(:chorus_view) { datasets(:searchquery_chorus_view_private) }

      context "when the user has access to the workspace" do
        let(:user) { owner }

        it "is included in search results" do
          create_and_record_search(user, :query => 'searchquery', :entity_type => 'Dataset') do |search|
            search.datasets.should include(chorus_view)
          end
        end

        it "includes chorus views associated with matching notes" do
          create_and_record_search(user, :query => 'workspacedatasetnotesearch', :entity_type => 'Dataset') do |search|
            search.datasets.should include(chorus_view)
          end
        end

        it "includes chorus views associated with matching comments" do
          create_and_record_search(user, :query => 'commentsearch', :entity_type => 'Dataset') do |search|
            search.datasets.should include(chorus_view)
          end
        end
      end

      context "when the user does not have access to the workspace" do
        let(:user) { users(:not_a_member) }

        it "is excluded from search results" do
          create_and_record_search(user, :query => 'searchquery', :entity_type => 'Dataset') do |search|
            data_source_account = FactoryGirl.build(:data_source_account, :data_source => chorus_view.data_source, :owner => user).tap { |a| a.save(:validate => false)}
            chorus_view.schema.database.data_source_accounts << data_source_account
            chorus_view.solr_index!
            search.datasets.should_not include(chorus_view)
          end
        end

        it "excludes results with matching notes on the chorus view" do
          create_and_record_search(user, :query => 'workspacedatasetnotesearch', :entity_type => 'Dataset') do |search|
            data_source_account = FactoryGirl.build(:data_source_account, :data_source => chorus_view.data_source, :owner => user).tap { |a| a.save(:validate => false)}
            chorus_view.schema.database.data_source_accounts << data_source_account
            chorus_view.solr_index!
            search.datasets.should_not include(chorus_view)
          end
        end

        it "excludes results with matching comments on the chorus view" do
          create_and_record_search(user, :query => 'commentsearch', :entity_type => 'Dataset') do |search|
            data_source_account = FactoryGirl.build(:data_source_account, :data_source => chorus_view.data_source, :owner => user).tap { |a| a.save(:validate => false)}
            chorus_view.schema.database.data_source_accounts << data_source_account
            chorus_view.solr_index!
            search.datasets.should_not include(chorus_view)
          end
        end
      end
    end

    describe "hdfs_entries" do
      it "includes the highlighted attributes" do
        create_and_record_search do |search|
          hdfs = search.hdfs_entries.first
          hdfs.highlighted_attributes.length.should == 2
          hdfs.highlighted_attributes[:parent_name][0].should == "<em>searchquery</em>"
          hdfs.highlighted_attributes[:path][0].should == "/<em>searchquery</em>"
        end
      end

      it "returns the HdfsDataSource objects found" do
        create_and_record_search do |search|
          search.hdfs_entries.length.should == 2
          search.hdfs_entries.should include(hdfs_entry)
        end
      end
    end

    describe "attachments" do
      it "includes the highlighted attributes" do
        create_and_record_search do |search|
          attachment = search.attachments.first
          attachment.highlighted_attributes.length.should == 1
          attachment.highlighted_attributes[:name][0].should =~ /\<em\>searchquery\<\/em\>/
        end
      end

      it "returns the Attachment objects found" do
        create_and_record_search do |search|
          search.attachments.first.should be_an Attachment
        end
      end

      let(:private_workfile_attachment) { attachments(:attachment_private_workfile) }
      let(:private_workspace_attachment) { attachments(:attachment_private_workspace) }
      let(:dataset_attachment) { attachments(:attachment_dataset) }

      context "when the attachment belongs on workspace and workfile" do
        let(:user_with_access) { users(:no_collaborators) }
        let(:user_without_access) { owner }

        it "excludes them where the user does not have access" do
          create_and_record_search(user_without_access, :query => 'searchquery', :entity_type => :attachment) do |search|
            search.attachments.should_not include(private_workspace_attachment)
            search.attachments.should_not include(private_workfile_attachment)
          end
        end

        it "includes them for users with access" do
          create_and_record_search(user_with_access, :query => 'searchquery', :entity_type => :attachment) do |search|
            search.attachments.should include(private_workspace_attachment)
            search.attachments.should include(private_workfile_attachment)
          end
        end
      end

      context "when the attachment belongs on datasets" do
        let(:user_with_access) { owner }
        let(:user_without_access) { users(:no_collaborators) }

        it "excludes them where the user does not have access" do
          create_and_record_search(user_without_access, :query => 'searchquery', :entity_type => :attachment) do |search|
            search.attachments.should_not include(dataset_attachment)
          end
        end

        it "includes them for users with access" do
          create_and_record_search(user_with_access, :query => 'searchquery', :entity_type => :attachment) do |search|
            search.attachments.should include(dataset_attachment)
          end
        end
      end

      context "when the attachment belongs on a chorus view" do
        let(:chorus_view) { datasets(:searchquery_chorus_view_private) }
        let(:attachment) { attachments(:attachment_on_chorus_view) }

        context "when the user has access to the workspace" do
          let(:user) { owner }

          it "includes attachments where the chorus_view is accessible" do
            create_and_record_search(user, :query => 'attachmentsearch', :entity_type => 'Attachment') do |search|
              search.attachments.should include(attachment)
            end
          end
        end

        context "when the user does not have access to the workspace" do
          let(:user) { users(:not_a_member) }

          it "excludes attachments when the chorus view is not accessible" do
            create_and_record_search(user, :query => 'attachmentsearch', :entity_type => 'Attachment') do |search|
              data_source_account = FactoryGirl.build(:data_source_account, :data_source => chorus_view.data_source, :owner => user).tap { |a| a.save(:validate => false)}
              chorus_view.schema.database.data_source_accounts << data_source_account
              chorus_view.solr_index!
              search.attachments.should_not include(attachment)
            end
          end
        end
      end
    end

    describe "highlighted notes" do
      it "includes highlighted notes in the highlighted_attributes" do
        create_and_record_search(owner, :query => 'greenplumsearch') do |search|
          search.data_sources.length.should == 2
          gpdb_data_source_with_notes = search.data_sources[1]
          gpdb_data_source_with_notes.search_result_notes.length.should == 2
          gpdb_data_source_with_notes.search_result_notes[0][:highlighted_attributes][:body][0].should == "no, not <em>greenplumsearch</em>"
        end
      end
    end

    describe "per_type=" do
      it "limits the search to not return more than some number of models" do
        create_and_record_search(owner, :query => 'alpha search', :per_type => 1) do |search|
          search.users.length.should == 1
          search.num_found[:users].should > 1
        end
      end
    end

    describe "tag search" do
      let(:tag) { Tag.find_by_name("alpha") }

      it "returns models with the specified tag" do
        create_and_record_search(owner, :query => tag.name, :tag => true, :per_type => 1) do |search|
          search.models[:workfiles].first.tags.should include tag
          search.models[:datasets].first.tags.should include tag
          search.models[:workspaces].first.tags.should include tag
        end
      end

      it "returns workfiles sorted by file_name" do
        query_params = { :query => "tagSort", :tag => true }
        record_with_vcr do
          restore_solr_index_after [Workfile, Tag] do
            public_workfile = workfiles(:public)
            tagged_workfile = workfiles(:tagged)

            [public_workfile, tagged_workfile].each do |w|
              w.tag_list = ["tagSort"]
              w.save!
            end
            Sunspot.commit

            search = Search.new(owner, query_params)
            search.workfiles.should be_sorted_by :file_name, true

            # changing the file names changes the order
            search.workfiles.second.update_attributes(:file_name => "aaa_" + search.workfiles.second.file_name)
            Sunspot.commit

            search = Search.new(owner, query_params)
            search.workfiles.should be_sorted_by :file_name, true
          end
        end
      end
    end

    context "when a record exists in solr, but not in the database" do
      before do
        public_workspace.delete
      end

      it "does not blow up" do
        create_and_record_search do |search|
          search.models
        end
      end
    end

    context "when searching workspace as the owner" do
      it "returns public and member workspaces but not others' private workspaces" do
        create_and_record_search do |search|
          search.workspaces.should include(public_workspace)
          search.workspaces.should include(private_workspace)
          search.workspaces.should_not include(private_workspace_not_a_member)
        end
      end

      it "includes notes" do
        events(:note_on_public_workspace).body.should == "notesearch forever"
        create_and_record_search(owner, :query => 'notesearch') do |search|
          workspace = search.workspaces.first
          workspace.search_result_notes[0][:highlighted_attributes][:body][0].should == "<em>notesearch</em> forever"
        end
      end

      it "excludes notes on others' private workspaces" do
        events(:note_on_no_collaborators_private).body.should == "notesearch never"
        create_and_record_search(owner, :query => 'notesearch') do |search|
          search.workspaces.should_not include private_workspace_not_a_member
        end
      end
    end

    context "when searching workspaces as the admin" do
      it "returns all workspaces" do
        create_and_record_search(admin, :query => 'searchquery', :entity_type => :workspace) do |search|
          search.workspaces.should include(public_workspace)
          search.workspaces.should include(private_workspace)
          search.workspaces.should include(private_workspace_not_a_member)
        end
      end
    end
  end
end

describe "SearchExtensions" do
  describe "security_type_name" do
    it "returns an array including the type_name of all ancestors" do
      ChorusView.security_type_name.should =~ [ChorusView.type_name, GpdbDataset.type_name, Dataset.type_name, RelationalDataset.type_name]
    end

    it "data_sources behave the same way" do
      ChorusView.first.security_type_name.should =~ ChorusView.security_type_name
    end
  end
end
