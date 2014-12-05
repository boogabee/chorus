require 'spec_helper'

describe HdfsDatasetPresenter, :type => :view do
  let(:dataset) { datasets(:hadoop) }
  let(:presenter) { HdfsDatasetPresenter.new(dataset, view, {:succinct => succinct, :with_content => with_content}) }
  let(:hash) { presenter.to_hash }
  let(:succinct) { false }
  let(:with_content) { false }

  before do
    any_instance_of(HdfsDataset) do |ds|
      stub(ds).contents { "contents" }
    end
    set_current_user(users(:admin))
  end

  describe "#to_hash" do
    context "when succinct is true" do
      let(:succinct) { true }

      it "includes appropriate fields and associates" do
        hash.should_not be_empty
        hash[:id].should == dataset.id
        hash[:file_mask].should == dataset.file_mask
        hash[:object_name].should == dataset.name
        hash[:hdfs_data_source][:id].should == dataset.hdfs_data_source.id
        hash[:hdfs_data_source][:name].should == dataset.hdfs_data_source.name
        hash[:entity_subtype].should == 'HDFS'
        hash[:object_type].should == 'MASK'
        hash[:content].should be_nil
      end
    end

    context "when we want the default hash" do
      it "includes appropriate fields and associates" do
        hash.should_not be_empty
        hash[:id].should == dataset.id
        hash[:file_mask].should == dataset.file_mask
        hash[:object_name].should == dataset.name
        hash[:hdfs_data_source][:id].should == dataset.hdfs_data_source.id
        hash[:hdfs_data_source][:name].should == dataset.hdfs_data_source.name
        hash[:workspace][:id].should == dataset.workspace.id
        hash[:entity_subtype].should == 'HDFS'
        hash[:object_type].should == 'MASK'
        hash[:content].should be_nil
      end

      context "when we want contents, too" do
        let(:with_content) { true }

        it "includes appropriate fields and associates" do
          hash.should_not be_empty
          hash[:id].should == dataset.id
          hash[:file_mask].should == dataset.file_mask
          hash[:object_name].should == dataset.name
          hash[:hdfs_data_source][:id].should == dataset.hdfs_data_source.id
          hash[:hdfs_data_source][:name].should == dataset.hdfs_data_source.name
          hash[:entity_subtype].should == 'HDFS'
          hash[:object_type].should == 'MASK'
          hash[:content].should == dataset.contents
        end
      end
    end
  end
end