require 'spec_helper'

describe HdfsEntryPresenter, :type => :view do
  let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }

  let(:options) {{}}
  let(:presenter) { HdfsEntryPresenter.new(entry, view, options) }

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    shared_examples_for :rendering_activities do
      let(:options) { {activity_stream: true} }
      it 'renders no tags' do
        hash.should_not have_key(:tags)
      end
    end

    context "for a directory" do
      let(:entry) do
        hdfs_data_source.hdfs_entries.create!({
           :path => "/data2",
           :modified_at => "2010-10-20 10:11:12",
           :size => '10',
           :is_directory => 'true',
           :content_count => 1,
           :hdfs_data_source => hdfs_data_source
       }, :without_protection => true)
      end

      before do
        mock(entry).ancestors { [{:name => "foo", :id => 1}] }
        stub(entry).entries { [] }
      end

      it "includes the fields" do
        hash[:id].should == entry.id
        hash[:name].should == "data2"
        hash[:path].should == "/"
        hash[:last_updated_stamp].should == "2010-10-20T10:11:12Z"
        hash[:size].should == 10
        hash[:is_deleted].should be_false
        hash[:is_dir].should be_true
        hash[:count].should be(1)
        hash[:tags].should be_an Array
        hash[:hdfs_data_source][:id].should == hdfs_data_source.id
        hash[:hdfs_data_source][:name].should == hdfs_data_source.name
        hash[:ancestors].should == [{:name => "foo", :id => 1}]
        hash.should_not have_key(:contents)
        hash.should_not have_key(:entries)
      end

      context "when deep option is specified" do
        let(:options) {{:deep => true}}

        it "includes entries" do
          hash[:id].should == entry.id
          hash[:entries].should == []
        end
      end

      it_behaves_like :rendering_activities
    end

    context "for a file" do
      let(:entry) do
        hdfs_data_source.hdfs_entries.create!({
             :path => "/data.file",
             :modified_at => "2010-10-20 10:11:12",
             :size => '10',
             :is_directory => 'false',
             :content_count => 1,
             :hdfs_data_source => hdfs_data_source
         }, :without_protection => true)
      end

      before do
        mock(entry).ancestors { [{:name => "foo", :id => 1}] }
        stub(entry).contents { "Content" }
      end

      it "includes the fields" do
        hash[:id].should == entry.id
        hash[:name].should == "data.file"
        hash[:path].should == "/"
        hash[:last_updated_stamp].should == "2010-10-20T10:11:12Z"
        hash[:size].should == 10
        hash[:is_deleted].should be_false
        hash[:is_dir].should be_false
        hash[:hdfs_data_source][:id].should == hdfs_data_source.id
        hash[:hdfs_data_source][:name].should == hdfs_data_source.name
        hash[:ancestors].should == [{:name => "foo", :id => 1}]
        hash.should_not have_key(:contents)
        hash.should_not have_key(:entries)
      end

      context "when deep option is specified" do
        let(:options) {{:deep => true}}

        it "includes contents" do
          hash[:id].should == entry.id
          hash[:contents].should == "Content"
        end
      end

      it_behaves_like :rendering_activities
    end
  end

  describe "complete_json?" do
    context "with a file" do
      let(:entry) { hdfs_entries(:hdfs_file) }

      it "is true" do
        presenter.complete_json?.should be_true
      end
    end

    context "with a directory" do
      let(:entry) { hdfs_entries(:directory) }

      context "when deep is not specified" do
        it "is not true" do
          presenter.complete_json?.should_not be_true
        end
      end

      context "when deep is specified" do
        let(:options) { {:deep => true} }

        it "is true" do
          presenter.complete_json?.should be_true
        end
      end
    end
  end
end
