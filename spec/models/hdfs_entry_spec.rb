require "spec_helper"

describe HdfsEntry do
  it_behaves_like "a notable model" do
    let!(:note) do
      Events::NoteOnHdfsFile.create!({
        :actor => users(:owner),
        :hdfs_file => model,
        :body => "This is the body"
      }, :as => :create)
    end

    let!(:model) { FactoryGirl.create(:hdfs_entry) }
  end

  it_should_behave_like "taggable models", [:hdfs_entries, :hdfs_file]

  describe "associations" do
    it { should belong_to(:hdfs_data_source) }
    it { should belong_to(:parent) }
    it { should have_many(:children) }
  end

  describe "validations" do
    it "should validate uniqueness of path, scoped to hdfs_data_source_id" do
      existing_entry = HdfsEntry.last
      duplicate_entry = HdfsEntry.new
      duplicate_entry.hdfs_data_source = existing_entry.hdfs_data_source
      duplicate_entry.path = existing_entry.path
      duplicate_entry.should have_error_on(:path)
    end

    it "should require a path that starts with a slash" do
      FactoryGirl.build(:hdfs_entry, :path => 'foo/bar.csv').should have_at_least(1).error_on(:path)
      FactoryGirl.build(:hdfs_entry, :path => '/foo/bar.csv').should be_valid
    end

    it { should validate_presence_of(:hdfs_data_source) }

    it { should ensure_length_of(:path).is_at_most(4096) }

    it 'supports paths of length 4096 in the database' do
      entry = hdfs_entries(:hdfs_file)
      entry.path = "/#{'a'*4095}"
      entry.save!
      entry.path.size.should == 4096
    end
  end

  describe ".list" do
    context "queries the hdfs query system and retrieve entries objects" do
      let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }

      before do
        @hdfs_results =
            [{
                 "path" => "/empty",
                 "size" => 10,
                 "is_directory" => "true",
                 "modified_at" => "2010-10-20 22:00:00",
                 'content_count' => 0
             },
             {
                 "path" => "/photo.png",
                 "size" => 10,
                 "is_directory" => "false",
                 "modified_at" => "2010-10-20 22:00:00",
                 'content_count' => 0
             }]
        HdfsEntry.delete_all # remove fixtures
        any_instance_of(Hdfs::QueryService) do |h|
          stub(h).list('/') { @hdfs_results }
        end
      end

      it "converts hdfs query results into entries" do
        list = HdfsEntry.list('/', hdfs_data_source).sort_by(&:path)
        first_result = list.first

        first_result.is_directory.should be_true
        first_result.path.should == '/empty'
        first_result.parent.path.should == '/'
        first_result.size.should == 10
        first_result.content_count.should == 0
        first_result.modified_at.should == "2010-10-20 22:00:00"
        first_result.hdfs_data_source.should == hdfs_data_source

        last_result = list.last
        last_result.path.should == '/photo.png'
        last_result.is_directory.should be_false
      end

      it "saves the hdfs entries to the database" do
        expect { HdfsEntry.list('/', hdfs_data_source) }.to change(HdfsEntry, :count).by(3)

        last_entry = HdfsEntry.last
        last_entry.path.should == '/photo.png'
        last_entry.parent.path.should == '/'
        last_entry.hdfs_data_source.should == hdfs_data_source
        last_entry.modified_at.should == "2010-10-20 22:00:00"
        last_entry.size.should == 10
        last_entry.is_directory.should == false
        last_entry.content_count.should == 0
      end

      it "stores a unique hdfs entry in the database" do
        expect { HdfsEntry.list('/', hdfs_data_source) }.to change(HdfsEntry, :count).by(3)
        list_again = nil
        expect { list_again = HdfsEntry.list('/', hdfs_data_source) }.to change(HdfsEntry, :count).by(0)

        first_result = list_again.first
        first_result.is_directory.should be_true
        first_result.path.should == '/empty'
        first_result.size.should == 10
        first_result.content_count.should == 0
        first_result.modified_at.should == "2010-10-20 22:00:00"
        first_result.hdfs_data_source.should == hdfs_data_source
      end

      it "marks hdfs entries that no longer exist as stale" do
        HdfsEntry.list('/', hdfs_data_source)
        hdfs_data_source.hdfs_entries.create!({:path => "/nonexistent_dir/goingaway.txt"}, :without_protection => true)
        expect { HdfsEntry.list('/', hdfs_data_source) }.to change(HdfsEntry.not_stale, :count).by(-2)
        hdfs_data_source.hdfs_entries.find_by_path("/nonexistent_dir/goingaway.txt").should be_stale
      end

      context "when no results come back from query service for the given path" do
        it "marks hdfs entries that no longer exist as stale" do
          HdfsEntry.list('/', hdfs_data_source)
          @hdfs_results = []
          HdfsEntry.list('/', hdfs_data_source)
          HdfsEntry.not_stale.count.should == 1
        end
      end

      context "when a directory and file share the same prefix, and the directory becomes stale" do
        it "should not mark the file as stale" do
          @hdfs_results =
              [{
                   "path" => "/directory",
                   "size" => 10,
                   "is_directory" => "true",
                   "modified_at" => "2010-10-20 22:00:00",
                   'content_count' => 0
               },
               {
                   "path" => "/directory.png",
                   "size" => 10,
                   "is_directory" => "false",
                   "modified_at" => "2010-10-20 22:00:00",
                   'content_count' => 0
               }]
          HdfsEntry.list('/', hdfs_data_source)
          directory_entry = HdfsEntry.find_by_path('/directory')
          file_entry = HdfsEntry.find_by_path('/directory.png')
          file_entry.should_not be_stale
          directory_entry.should_not be_stale
          @hdfs_results =
              [{
                   "path" => "/directory.png",
                   "size" => 10,
                   "is_directory" => "false",
                   "modified_at" => "2010-10-20 22:00:00",
                   'content_count' => 0
               }]
          HdfsEntry.list('/', hdfs_data_source)

          file_entry.reload.should_not be_stale
          directory_entry.reload.should be_stale
        end
      end

      it "marks stale entries as not stale if they reappear" do
        HdfsEntry.list('/', hdfs_data_source)
        hdfs_data_source.hdfs_entries.where("parent_id IS NOT NULL").each(&:mark_stale!)
        HdfsEntry.list('/', hdfs_data_source)
        hdfs_data_source.hdfs_entries.where("stale_at IS NOT NULL").length.should == 0
      end

      it "does not update records if no changes have occurred" do
        HdfsEntry.list('/', hdfs_data_source)
        update_time = 1.year.ago
        hdfs_data_source.hdfs_entries.update_all(:updated_at => update_time)
        dont_allow(Sunspot.session).index
        HdfsEntry.list('/', hdfs_data_source)
        hdfs_data_source.hdfs_entries.where(:updated_at => update_time).count.should == hdfs_data_source.hdfs_entries.count
      end

      context "the parent-child relationship" do
        before do
          any_instance_of(Hdfs::QueryService) do |h|
            stub(h).list('/') do
              [{
                   "path" => "/parent",
                   "size" => 10,
                   "is_directory" => "true",
                   "modified_at" => "2010-10-20 22:00:00",
                   'content_count' => 0
               }]
            end

            stub(h).list('/parent/') do
              [{
                   "path" => "/parent/child",
                   "size" => 10,
                   "is_directory" => "false",
                   "modified_at" => "2010-10-20 22:00:00",
                   'content_count' => 1
               }]
            end
          end
        end

        let(:child) { HdfsEntry.list('/parent/', hdfs_data_source).first }
        let(:parent) { HdfsEntry.list('/', hdfs_data_source).first }

        context "when parent is created after the child" do
          it "updates the parent-child relationship" do
            child
            parent
            child.reload.parent.should == parent
            parent.children.should include(child)
          end
        end

        context "when parent is created before the child" do
          it "updates the parent-child relationship" do
            parent
            child
            child.parent.should == parent
            parent.children.should include(child)
          end
        end
      end
    end
  end

  describe ".create" do
    let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }
    let(:child) { hdfs_data_source.hdfs_entries.create!({:path => "/nonexistent_dir/goingaway.txt"},
                                                       :without_protection => true) }
    it "creates the parent" do
      child.parent.should be_a(HdfsEntry)
      child.parent.path.should == "/nonexistent_dir"
      child.parent.is_directory.should be_true
    end

    it "has a parent_path" do
      child.parent_path.should == "/nonexistent_dir"
    end

    it "creates the root directory with nil parent" do
      root = child.parent.parent
      root.should be_a(HdfsEntry)
      root.path.should == "/"
      root.parent == nil
      root.reload
      root.is_directory.should be_true
    end
  end

  describe "#file" do
    let(:hdfs_data_source) { FactoryGirl.build_stubbed(:hdfs_data_source) }

    let(:directory_entry) do
      HdfsEntry.new({
          :path => "/abc",
          :size => 10,
          :is_directory => true,
          :modified_at => Time.parse("2010-10-20 22:00:00"),
          :content_count => 4,
          :hdfs_data_source => hdfs_data_source
      }, :without_protection => true)
    end

    let(:file_entry) do
      HdfsEntry.new({
          :path => "/hello.sql",
          :is_directory => false,
          :modified_at => Time.parse("2010-10-20 22:00:00"),
          :size => 4096,
          :hdfs_data_source => hdfs_data_source
      }, :without_protection => true)
    end

    context "entry is a directory" do
      it "returns nil" do
        directory_entry.file.should be_nil
      end
    end

    context "entry is a file" do
      it "creates a Hdfs file from the entry" do
        file = file_entry.file

        file.path.should == "/hello.sql"
        file.hdfs_data_source.should == hdfs_data_source
        file.modified_at.should == file_entry.modified_at
      end
    end
  end

  describe "search fields" do
    let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }
    let(:hdfs_entry) { hdfs_data_source.hdfs_entries.create!({:path => "/foo/bar/baz.txt"}, :without_protection => true) }

    it "returns the file name for name" do
      hdfs_entry.name.should == 'baz.txt'
    end

    it "returns the directory name for parent_name" do
      hdfs_entry.parent_name.should == 'bar'
    end

    it "indexes text fields" do
      HdfsEntry.should have_searchable_field :name
      HdfsEntry.should have_searchable_field :parent_name
    end

    it "should index files" do
      mock(hdfs_entry).solr_index
      hdfs_entry.save!
    end

    it "does not index directories" do
      hdfs_entry = HdfsEntry.new({:path => "/foo/bar/baz", :hdfs_data_source_id => hdfs_data_source.id, :is_directory => true}, :without_protection => true)
      dont_allow(hdfs_entry).solr_index
      hdfs_entry.save!
    end

    it "does not index stale records" do
      hdfs_entry = HdfsEntry.new({:path => "/foo/bar/baz", :hdfs_data_source_id => hdfs_data_source.id, :is_directory => false}, :without_protection => true)
      hdfs_entry.mark_stale!
      dont_allow(hdfs_entry).solr_index
      hdfs_entry.save!
    end
  end

  describe "#ancestors" do
    let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }
    let(:root) {
      FactoryGirl.build(
          :hdfs_entry,
          :hdfs_data_source_id => hdfs_data_source.id,
          :path => '/',
          :is_directory => true,
          :modified_at => "2010-10-20 22:00:00",
          :content_count => 1,
          :id => 1
      )}
    context "when the hdfs_entry is root" do
      it "should be an empty array" do
        root.ancestors.should == []
      end
    end

    context "when the hsfd_entry is not root" do
      let(:dir) { FactoryGirl.build(
          :hdfs_entry,
          :hdfs_data_source_id => hdfs_data_source.id,
          :path => '/foo',
          :is_directory => true,
          :modified_at => "2010-10-20 22:00:00",
          :content_count => 1,
          :parent => root,
          :id => 2
      )}

      let(:entry) {FactoryGirl.build(
          :hdfs_entry,
          :hdfs_data_source_id => hdfs_data_source.id,
          :path => '/foo/bar.csv',
          :is_directory => false,
          :modified_at => "2010-10-20 22:00:00",
          :content_count => 0,
          :parent => dir,
          :id => 3
      )}
      it "returns the ids and names of all ancestors in order, root last" do
        entry.ancestors.should == [
            {:name => dir.name, :id => dir.id},
            {:name => hdfs_data_source.name, :id => root.id}
        ]
      end
    end
  end

  describe "#contents" do
    let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }
    let(:entry) { hdfs_data_source.hdfs_entries.build(:path => "/file.txt") }
    before do
      any_instance_of(Hdfs::QueryService) do |h|
        stub(h).show('/file.txt') { ["content"] }
      end
    end

    it "retrieves file content from the query service" do
      entry.contents.should == ['content']
    end

    context "corrupted file" do
      before do
        any_instance_of(Hdfs::QueryService) do |h|
          stub(h).show('/file.txt') { raise FileNotFoundError, "File not found on HDFS: file.txt" }
        end
      end
      it "raises HdfsContentsError when not able to read the file" do
        expect {
          entry.contents
        }.to raise_error(HdfsEntry::HdfsContentsError)
      end
    end
  end

  describe "#statistics" do
    let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }
    let(:entry) { hdfs_entries(:hdfs_file) }
    let(:details) { OpenStruct.new(FactoryGirl.attributes_for(:hdfs_entry_statistics)) }
    let(:statistics) { entry.statistics }

    before do
      any_instance_of(Hdfs::QueryService) do |h|
        stub(h).details { details }
      end
    end

    it "retrieve the file statistics" do
      statistics.should be_a HdfsEntryStatistics
      statistics.owner.should == details.owner
    end
  end

  describe "#highlighted_attributes" do
    it "includes path in the highlighted attributes" do
      hdfs_entry = HdfsEntry.new({:path => "/foo.txt"}, :without_protection => true)
      hdfs_entry.highlighted_attributes = {:name => [""]}
      hdfs_entry.highlighted_attributes.should have_key(:path)
    end
  end

  describe "#highlighted_path" do
    it "includes highlighted parent name and not file name" do
      hdfs_entry = HdfsEntry.new({:path => "/foo/bar/baz.txt"}, :without_protection => true)
      hdfs_entry.highlighted_attributes = {:parent_name => ["BAD"]}
      hdfs_entry.highlighted_path.should == "/foo/BAD"
    end

    it "returns path without file if nothing is highlighted" do
      hdfs_entry = HdfsEntry.new({:path => "/foo/bar/baz.txt"}, :without_protection => true)
      hdfs_entry.highlighted_attributes = {}
      hdfs_entry.highlighted_path.should == "/foo/bar"
    end
  end

  describe "destroy_entries" do
    it "destroys entries for given data source id" do
      data_source = hdfs_data_sources(:hadoop)
      data_source.destroy
      entries = data_source.hdfs_entries
      entry_count = entries.count
      call_count = 0
      any_instance_of(HdfsEntry) do |entry|
        stub.proxy(entry).destroy do |result|
          call_count += 1
        end
      end
      entries.should_not be_empty
      HdfsEntry.destroy_entries(data_source.id)
      entries.reload.should be_empty

      #Ensure that we don't delete children multiple times due to a dependent destroy
      call_count.should == entry_count
    end
  end

  it_behaves_like 'a soft deletable model' do
    let(:model) { hdfs_entries(:hdfs_file) }
  end
end
