require 'spec_helper'

describe Import, :greenplum_integration do
  let(:user)  { schema.data_source.owner }
  let(:workspace) { workspaces(:real) }
  let(:database) { GreenplumIntegration.real_database }
  let(:schema) { database.schemas.find_by_name('test_schema') }
  let(:account) { GreenplumIntegration.real_account }
  let(:gpdb_data_source) { GreenplumIntegration.real_data_source }
  let(:source_dataset) { workspace.sandbox.datasets.find_by_name('candy_one_column') }

  let(:import) do
    WorkspaceImport.create(
        {
            :workspace => workspace,
            :to_table => 'new_table1234',
            :new_table => true,
            :source_dataset => source_dataset,
            :user => user
        }, :without_protection => true)
  end

  before { workspace.update_attribute :sandbox_id, schema.id }

  describe "associations" do
    it { should belong_to(:source) }
    it { should belong_to :user }
  end

  describe "validations" do
    let(:import) do
      WorkspaceImport.new.tap do |i|
        i.workspace = workspace
        i.to_table = 'new_table1234'
        i.new_table = true
        i.source_dataset = i.workspace.sandbox.datasets.find_by_name('candy_one_column')
        i.user = user
      end
    end

    it "validates the presence of to_table" do
      import = FactoryGirl.build(:import, :workspace => workspace, :user => user, :to_table => nil)
      import.should have_error_on(:to_table)
    end

    it "validates the presence of source_dataset if no file_name present" do
      import = FactoryGirl.build(:import, :workspace => workspace, :user => user, :source => nil, :file_name => nil)
      import.should have_error_on(:scoped_source)
      import.should have_error_on(:file_name)
    end

    it "does not validate the presence of source_dataset if file_name present" do
      import = FactoryGirl.build(:import, :workspace => workspace, :user => user, :source => nil, :file_name => "foo.csv")
      import.should be_valid
    end

    it "validates the presence of user" do
      import = FactoryGirl.build(:import, :workspace => workspace, :user => nil)
      import.should have_error_on(:user)
    end

    it "validates that the to_table does not exist already if it is a new table" do
      import.to_table = "master_table1"
      import.should have_error_on(:base).with_message(:table_exists)
    end

    it "is valid if an old import's to_table exists" do
      import.to_table = 'second_candy_one_column'
      import.save(:validate => false)
      import.reload
      import.should be_valid
    end

    it "validates that the source and destination have consistent schemas" do
      any_instance_of GpdbDataset do |dataset|
        stub(dataset).can_import_into(anything) { false }
      end
      import.to_table = 'pg_all_types'
      import.new_table = false

      import.should have_error_on(:base, :table_not_consistent)
    end

    it "sets the destination_dataset before validation" do
      any_instance_of GpdbDataset do |dataset|
        stub(dataset).can_import_into(anything) { true }
      end
      import.to_table = 'master_table1'
      import.new_table = false
      import.should be_valid
      import.destination_dataset.should == import.workspace.sandbox.datasets.find_by_name('master_table1')
    end

    it "should change a previously set destination dataset" do
      any_instance_of GpdbDataset do |dataset|
        stub(dataset).can_import_into(anything) { true }
      end
      import.destination_dataset = import.source_dataset
      import.to_table = 'master_table1'
      import.new_table = false
      import.should be_valid
      import.destination_dataset.should == import.workspace.sandbox.datasets.find_by_name('master_table1')
    end

    it "is valid if an imports table become inconsistent after saving" do
      import.save
      any_instance_of GpdbDataset do |dataset|
        stub(dataset).can_import_into(anything) { false }
      end

      import.should be_valid
    end

    it "validates that the sample_count is between 0 and 19 digits long" do
      import.sample_count = '500'
      import.should be_valid

      import.sample_count = ''
      import.should be_valid

      import.sample_count = nil
      import.should be_valid

      import.sample_count = '1' * 10
      import.should be_valid

      import.sample_count = '1' * 11
      import.should_not be_valid
      import.should have_error_on(:sample_count, :invalid)
    end
  end

  describe "#handle" do
    before do
      import.created_at = Time.at(123456789)
      import.id = 42
    end

    it "returns the right handle" do
      import.handle.should == "123456789_42"
    end
  end

  describe "#update_status" do
    it "updates finished_at" do
      -> {
        import.update_status(:passed)
      }.should change(import, :finished_at)
    end

    context "when import passed" do
      it "marks the import as success and refreshes its schema" do
        mock(import).mark_as_success
        mock(import).index_destination_dataset
        import.update_status(:passed)
      end

      it "sets success to true" do
        -> {
          import.update_status(:passed)
        }.should change(import, :success).to(true)
      end
    end

    context "when import failed" do
      it "creates failed event and notification" do
        mock(import).create_failed_event_and_notification("a message")
        import.update_status(:failed, "a message")
      end

      it "sets success to false" do
        -> {
          import.update_status(:failed)
        }.should change(import, :success).to(false)
      end
    end
  end

  describe "#source_dataset" do
    it "returns source_dataset even if it is deleted" do
      import.source_dataset.should == source_dataset
      source_dataset.destroy
      import.reload.source_dataset.should == source_dataset
    end
  end

  describe "#workspace" do
    it "returns workspace even if it is deleted" do
      import.workspace.should == workspace
      workspace.destroy
      import.reload.workspace.should == workspace
    end
  end

  describe "subclasses" do
    it "responds to presenter_class" do
      Import.subclasses.each do |subclass|
        subclass.should respond_to(:presenter_class)
      end
    end
  end

  describe "unfinished" do
    let(:import) { imports(:one) }
    it "includes not yet started imports" do
      import.started_at.should be_blank
      Import.unfinished.should include(import)
    end

    it "includes started, but not yet complete imports" do
      import.touch(:started_at)
      Import.unfinished.should include(import)
    end
  end

  describe "cancel" do
    let(:import) { imports(:one) }

    it "delegates cancellation to the table copier" do
      mock(import.copier_class).cancel(import)
      import.cancel(false, "canceled!")
    end
  end

  describe "mark_as_canceled!" do
    let(:message) { "canceled!" }

    it "flags the current qc job as canceled" do
      import.mark_as_canceled!(message)

      import.reload.canceled_at.should_not be_nil
      import.cancel_message.should == message
    end
  end

  describe "#canceled?" do
    it "returns true when the import has a canceled_at date" do
      import.touch(:canceled_at)
      import.should be_canceled
    end

    it "returns false when the import has no canceled_at date" do
      import.canceled_at = nil
      import.should_not be_canceled
    end
  end

  describe "#runnable?" do
    it "returns false when the import has a canceled_at date" do
      import.touch(:canceled_at)
      import.should_not be_runnable
    end

    it "returns false when the import has succeeded" do
      import.success = true
      import.should_not be_runnable
    end

    it "returns false when the import has failed" do
      import.success = false
      import.should_not be_runnable
    end

    it "returns true when the import has not been marked as succeeded or canceled" do
      import.success = nil
      import.canceled_at = nil
      import.should be_runnable
    end
  end
end
