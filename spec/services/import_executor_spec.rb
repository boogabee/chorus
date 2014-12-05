require 'spec_helper'
require 'fakefs/spec_helpers'

describe ImportExecutor do
  let(:user) { users(:owner) }
  let(:source_dataset) { datasets(:table) }
  let(:destination) { workspaces(:public) }
  let(:sandbox) { destination.sandbox }
  let(:destination_table_name) { import.to_table }
  let(:database_url) { sandbox.database.connect_with(account).db_url }
  let(:account) { sandbox.data_source.account_for_user!(user) }

  let!(:import_created_event) do
    Events::WorkspaceImportCreated.by(user).add(
      :workspace => destination,
      :dataset => nil,
      :destination_table => destination_table_name,
      :reference_id => import.id,
      :reference_type => Import.name,
      :source_dataset => source_dataset
    )
  end

  let(:import) do
    FactoryGirl.build(:import,
                      :user => user,
                      :workspace => destination,
                      :source_dataset => source_dataset).tap { |i| i.save(:validate => false) }
  end
  let(:import_failure_message) { "" }

  before do
    stub(Alpine::API).delete_work_flow.with_any_args
  end

  describe ".run" do
    context "when the import has already been run" do
      before do
        import.success = true
        import.save!
      end

      it "skips the import" do
        any_instance_of ImportExecutor do |executor|
          mock(executor).run.with_any_args.times(0)
        end
        ImportExecutor.run(import.id)
      end
    end

    context "when the import has already been canceled" do
      before do
        import.canceled_at = Time.now
        import.save!
      end

      it "skips the import" do
        any_instance_of ImportExecutor do |executor|
          dont_allow(executor).run.with_any_args
        end
        ImportExecutor.run(import.id)
      end
    end
  end

  describe "#run" do
    def mock_copier
      mock(TableCopier).new(anything) do |*args|
        raise import_failure_message if import_failure_message.present?
        yield *args if block_given?
        Object.new.tap { |o| stub(o).start }
      end
    end

    before do
      any_instance_of(Schema) do |schema|
        stub(schema).refresh_datasets.with_any_args do
          FactoryGirl.create(:gpdb_table, :name => destination_table_name, :schema => sandbox)
        end
      end
    end

    let(:copier_start) do
      mock_copier
      ImportExecutor.new(import).run
    end

    it "creates a new table copier as specified by the import and runs it" do
      class FooCopier
        def initialize(attrs={})
        end

        def start
          raise "started FooCopier"
        end
      end
      stub(import).copier_class { FooCopier }
      expect { ImportExecutor.new(import).run }.to raise_error("started FooCopier")
    end

    it "sets the started_at time" do
      expect {
        copier_start
      }.to change(import, :started_at).from(nil)
      import.started_at.should be_within(1.hour).of(Time.current)
    end

    it "uses the import id and created_at time in the pipe_name" do
      mock_copier do |attributes|
        attributes[:pipe_name].should == "#{import.created_at.to_i}_#{import.id}"
      end
      ImportExecutor.run(import.id)
    end

    context "when the import succeeds" do
      it_behaves_like :import_succeeds, :copier_start
    end

    context "when the import fails" do
      let(:import_failure_message) { "some crazy error" }
      let(:run_failing_import) do
        expect {
          copier_start
        }.to raise_error import_failure_message
      end

      it_behaves_like :import_fails_with_message, :run_failing_import, "some crazy error"
    end

    context "where the import source dataset has been deleted" do
      before do
        any_instance_of(GreenplumConnection) do |data_source|
          stub(data_source).running? { false }
        end
        source_dataset.destroy
        import.reload # reload the deleted source dataset
      end

      let(:error_message) { "Original source dataset #{source_dataset.scoped_name} has been deleted" }
      let(:copier_start) {
        ImportExecutor.new(import).run
      }

      it "raises an error" do
        expect {
          copier_start
        }.to raise_error error_message
      end

      it "creates a WorkspaceImportFailed" do
        expect {
          copier_start
        }.to raise_error error_message
      end
    end

    context "where the workspace has been deleted" do
      let(:error_message) { "Destination workspace #{destination.name} has been deleted" }

      before do
        destination.destroy
        import.reload # reload the deleted source dataset
      end

      let(:copier_start) {
        ImportExecutor.new(import).run
      }

      it "raises an error" do
        expect {
          copier_start
        }.to raise_error error_message
      end

      it "creates a WorkspaceImportFailed" do
        expect {
          expect {
            copier_start
          }.to raise_error error_message
        }.to change(Events::WorkspaceImportFailed, :count).by(1)

        event = Events::WorkspaceImportFailed.last
        event.error_message.should == error_message
        event.workspace.should == destination
      end
    end
  end
end
