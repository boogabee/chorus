require 'spec_helper'

describe ImportPresenter, :type => :view do
  let(:import) { imports(:three) }

  describe "#to_hash" do
    let(:presenter) { ImportPresenter.new(import, view) }
    let(:hash) { presenter.to_hash }

    it "includes the right keys" do
      hash.should have_key(:to_table)
      hash.should have_key(:started_stamp)
      hash.should have_key(:completed_stamp)
      hash.should have_key(:success)
      hash.should have_key(:file_name)
      hash.should have_key(:workspace_id)
    end

    it "presents the source dataset" do
      import.source = datasets(:source_table)
      hash[:source_dataset].should have_key(:id)
      hash[:source_dataset].should have_key(:object_name)
    end

    it "presents the destination dataset if it exists" do
      import.destination_dataset = datasets(:table)
      import.destination_dataset.should == datasets(:table)

      hash[:destination_dataset].should have_key(:id)
      hash[:destination_dataset].should have_key(:object_name)
    end

    it "still presents a dataset with a name even if it doesn't exist yet" do
      import.destination_dataset_id = nil
      hash[:destination_dataset][:id].should be_nil
      hash[:destination_dataset][:object_name].should == import.to_table
    end

    it "presents the destination dataset with a name and a nil id if it has been deleted" do
      dataset = datasets(:table)
      stub(dataset).cancel_imports
      dataset.destroy
      dataset.id.should_not be_nil
      import.destination_dataset_id = dataset.id

      hash[:destination_dataset].fetch(:id).should be_nil
      hash[:destination_dataset].fetch(:object_name).should == import.to_table
    end

    it "returns nil for source_dataset_name if it doesn't exist" do
      import.source_id = -1
      import.save(:validate => false)
      import.reload
      hash[:source_dataset_name].should be_nil
    end
  end
end