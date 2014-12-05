require "spec_helper"

describe TypeAheadSearch do
  let(:owner) { users(:owner) }

  describe ".new" do
    it "takes current user and search params" do
      search = described_class.new(owner, :query => 'fries')
      search.current_user.should == owner
      search.query.should == 'fries'
    end
  end

  describe "#search" do
    it "searches for all types with query" do
      search = described_class.new(owner, :query => 'bob')
      search.search
      Sunspot.session.should be_a_search_for(Attachment)
      Sunspot.session.should be_a_search_for(User)
      Sunspot.session.should be_a_search_for(GpdbDataSource)
      Sunspot.session.should be_a_search_for(HdfsDataSource)
      Sunspot.session.should be_a_search_for(GnipDataSource)
      Sunspot.session.should be_a_search_for(Workspace)
      Sunspot.session.should be_a_search_for(Workfile)
      Sunspot.session.should be_a_search_for(Dataset)
      Sunspot.session.should be_a_search_for(HdfsEntry)
      Sunspot.session.should be_a_search_for(OracleDataSource)
      Sunspot.session.should be_a_search_for(PgDataSource)
      Sunspot.session.should have_search_params(:fulltext) {
        fulltext 'bob', :fields => [:name, :first_name, :last_name, :file_name]
      }
    end

    it "supports pagination" do
      search = described_class.new(owner, :query => 'bob', :per_page => 42)
      search.search
      Sunspot.session.should have_search_params(:paginate, :page => 1, :per_page => 42)
    end
  end

  context "with solr enabled" do
    let(:admin) { users(:admin) }

    let(:private_workspace) { workspaces(:typeahead_private) }
    let(:public_workspace) { workspaces(:typeahead_public) }
    let(:private_workspace_not_a_member) { workspaces(:typeahead_private_no_members) }

    before do
      index_solr_fixtures_once
    end

    def create_and_record_search(*args)
      if args.empty?
        tape_name = "type_ahead_search_spec"
        args = [owner, {:query => 'typeahead', :per_page => 20}]
      end

      record_with_vcr(tape_name) do
        search = described_class.new(*args)
        yield search
      end
    end

    it "returns models" do
      create_and_record_search do |search|
        search.results.should include(workspaces(:typeahead))
        search.results.should include(workfiles(:typeahead))
        search.results.should include(hdfs_entries(:typeahead))
        search.results.should include(users(:typeahead))
        search.results.should include(hdfs_data_sources(:typeahead))
        search.results.should include(data_sources(:typeahead_jdbc_source))
        search.results.should include(datasets(:typeahead_gpdb_table))
      end
    end

    describe "partial word matching" do
      context "with a hypen" do
        it "matches when there is an exact match" do
          create_and_record_search owner, {:query => "typeahead-with-dash"} do |search|
            search.results.should include(datasets(:typeahead_with_dash))
          end
        end
        it "matches when there is a partial match" do
          create_and_record_search owner, {:query => "typeahead-wi"} do |search|
            search.results.should include(datasets(:typeahead_with_dash))
          end
        end
      end

      context "with an underscore" do
        it "matches when there is an exact match" do
          create_and_record_search owner, {:query => "typeahead_with_underscore"} do |search|
            search.results.should include(datasets(:typeahead_with_underscore))
          end
        end
        it "matches when there is a partial match" do
          create_and_record_search owner, {:query => "typeahead_wi"} do |search|
            search.results.should include(datasets(:typeahead_with_underscore))
          end
        end
      end

      it "matches stems" do
        create_and_record_search owner, {:query => "plural"} do |search|
          search.results.should include(datasets(:plurals))
        end
      end
    end

    describe "when typeahead search begins with a special character" do
      %w{+ -}.each do | character |
        it "returns empty results for strings of just #{character}" do
          create_and_record_search owner, {:query => character } do |search|
            search.results.should be_empty
          end
        end

        it "returns empty results for strings beginning with #{character}" do
          create_and_record_search owner, {:query => character + "typeahead" } do |search|
            search.results.should be_empty
          end
        end
      end
    end

    context "when searching workspace as the owner" do
      it "returns public and member workspaces but not others' private workspaces" do
        create_and_record_search do |search|
          search.results.should include(public_workspace)
          search.results.should include(private_workspace)
          search.results.should_not include(private_workspace_not_a_member)
        end
      end
    end

    context "when searching workspaces as the admin" do
      it "returns all workspaces" do
        create_and_record_search(admin, :query => 'typeahead', :per_page => 30) do |search|
          search.results.should include(public_workspace)
          search.results.should include(private_workspace)
          search.results.should include(private_workspace_not_a_member)
        end
      end
    end
  end
end
