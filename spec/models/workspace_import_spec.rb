require 'spec_helper'

describe WorkspaceImport do
  let(:import) { imports(:one) }
  let(:user) { import.user }

  describe 'associations' do
    it { should belong_to(:scoped_workspace) }
  end

  describe 'creating' do
    let(:source_dataset) { datasets(:oracle_table) }
    let(:workspace) { workspaces(:public) }

    it 'creates a WorkspaceImportCreated event' do
      import = WorkspaceImport.new
      import.to_table = 'the_new_table'
      import.source_dataset = source_dataset
      import.workspace = workspace
      import.user = user
      expect {
        import.save!(:validate => false)
      }.to change(Events::WorkspaceImportCreated, :count).by(1)

      event = Events::WorkspaceImportCreated.last
      event.actor.should == user
      event.dataset.should be_nil
      event.reference_id.should == import.id
      event.reference_type.should == 'Import'
      event.source_dataset.should == source_dataset
      event.workspace.should == workspace
      event.destination_table.should == 'the_new_table'
    end
  end

  describe '#schema' do
    it 'is the sandbox of the workspace' do
      import.schema.should == import.workspace.sandbox
    end
  end

  describe '#create_passed_event_and_notification' do
    it 'creates a WorkspaceImportSuccess event' do
      expect {
        import.create_passed_event_and_notification
      }.to change(Events::WorkspaceImportSuccess, :count).by(1)
    end

    it 'creates a notification for the import creator' do
      expect {
        import.create_passed_event_and_notification
      }.to change(Notification, :count).by(1)
      notification = Notification.last
      notification.recipient_id.should == import.user_id
      notification.event_id.should == Events::WorkspaceImportSuccess.last.id
    end
  end

  describe '#create_failed_event_and_notification' do
    it 'creates a WorkspaceImportFailed event' do
      expect {
        import.create_failed_event_and_notification("message")
      }.to change(Events::WorkspaceImportFailed, :count).by(1)
      event = Events::WorkspaceImportFailed.last

      event.actor.should == import.user
      event.error_message.should == "message"
      event.workspace.should == import.workspace
      event.source_dataset.should == import.source_dataset
      event.destination_table.should == import.to_table
    end

    it 'creates a notification for the import creator' do
      expect {
        import.create_failed_event_and_notification("message")
      }.to change(Notification, :count).by(1)
      notification = Notification.last
      notification.recipient_id.should == import.user_id
      notification.event_id.should == Events::WorkspaceImportFailed.last.id
    end
  end

  describe "#cancel" do
    let(:source_connection) { Object.new }
    let(:destination_connection) { Object.new }
    let(:destination_table_name) { import.to_table }
    let(:sandbox) { import.schema }
    let(:import) do
      imp = imports(:now)
      imp.update_attribute(:to_table, datasets(:table).name)
      imp
    end

    let!(:import_created_event) do
      Events::WorkspaceImportCreated.by(user).add(
        :workspace => import.workspace,
        :dataset => nil,
        :destination_table => destination_table_name,
        :reference_id => import.id,
        :reference_type => Import.name,
        :source_dataset => import.source_dataset
      )
    end

    before do
      stub(import).log.with_any_args
      stub(import.source_dataset).connect_as(user) { source_connection }
      stub(import.schema).connect_as(user) { destination_connection }
      mock(import.copier_class).cancel(import)

      any_instance_of(Schema) do |schema|
        stub(schema).refresh_datasets.with_any_args do
          FactoryGirl.create(:gpdb_table, :name => destination_table_name, :schema => sandbox)
        end
      end
    end

    describe "when the import is marked as successful" do
      let(:cancel_import) do
        import.cancel(true)
      end

      it_behaves_like :import_succeeds, :cancel_import
    end

    describe "when the import is marked as failed with a message" do
      let(:cancel_import) do
        import.cancel(false, "some crazy error")
      end

      it_behaves_like :import_fails_with_message, :cancel_import, "some crazy error"
    end
  end

  describe '#copier_class' do
    let(:import) { FactoryGirl.build(:import, :source_dataset => source_dataset, :workspace => workspace) }
    let(:copier_class) { import.copier_class }

    context 'the destination is greenplum' do
      let(:workspace) { workspaces(:public) }

      context 'when the source is in the same database' do
        let(:source_dataset) { datasets(:table) }
        it('is TableCopier') { copier_class.should == TableCopier }
      end

      context 'when the source is in a different greenplum database' do
        let(:source_dataset) { datasets(:searchquery_table) }
        it('is GpfdistTableCopier') { copier_class.should == GpfdistTableCopier }
      end

      context 'when the source is in a different (postgres) database' do
        let(:source_dataset) { datasets(:pg_table) }
        it('is MultiPgTableCopier') { copier_class.should == MultiPgTableCopier }
      end

      context 'when the source is in an oracle database' do
        let(:source_dataset) { datasets(:oracle_table) }
        it('is OracleTableCopier') { copier_class.should == OracleTableCopier }
      end
    end

    context 'the destination is postgres' do
      let(:workspace) { FactoryGirl.create(:workspace, :sandbox => schemas(:pg)) }

      context 'when the source is in the same database' do
        let(:source_dataset) { datasets(:pg_table) }
        it('is TableCopier') { copier_class.should == TableCopier }
      end

      context 'when the source is in a greenplum database' do
        let(:source_dataset) { datasets(:table) }
        it('is MultiPgTableCopier') { copier_class.should == MultiPgTableCopier }
      end

      context 'when the source is in a different postgres database' do
        let(:other_db) { FactoryGirl.create(:pg_database, :data_source => data_sources(:postgres)) }
        let(:other_db_schema) { FactoryGirl.create(:pg_schema, :database => other_db) }
        let(:source_dataset) { FactoryGirl.create(:pg_table, :schema => other_db_schema) }
        it('is MultiPgTableCopier') { copier_class.should == MultiPgTableCopier }
      end

      context 'when the source is in an oracle database' do
        let(:source_dataset) { datasets(:oracle_table) }
        it('is OracleTableCopier') { copier_class.should == OracleTableCopier }
      end
    end
  end

  describe "associating dataset to workspace" do
    let(:workspace) { import.workspace }
    let(:destination) { datasets(:table) }

    before do
      stub(import).mark_as_success
      import.update_attributes(:new_table => false)
    end

    context "if the workspace does not automatically include sandbox datasets" do
      before do
        workspace.update_attributes(:show_sandbox_datasets => false)
      end

      context "for a successful import" do
        it "should associate the destination dataset with the workspace" do
          workspace.has_dataset?(destination).should be_false
          import.destination_dataset = destination
          import.update_status(:passed)
          workspace.has_dataset?(destination).should be_true
        end

        it "should not raise an error if the destination dataset is already associated" do
          workspace.associate_datasets(user, [destination])
          workspace.has_dataset?(destination).should be_true
          import.destination_dataset = destination
          import.update_status(:passed)
          workspace.has_dataset?(destination).should be_true
        end
      end

      context "for a failed import" do
        it "should associate an existing table" do
          workspace.has_dataset?(destination).should be_false
          import.destination_dataset = destination
          import.update_status(:failed)
          workspace.has_dataset?(destination).should be_true
        end

        it "should not associate a new table (it doesn't exist)" do
          import.update_attributes(:new_table => true)
          dont_allow(workspace).associate_datasets.with_any_args
          import.update_status(:failed)
        end
      end
    end

    context "if the workspace does automatically include sandbox datasets" do
      before do
        workspace.update_attributes(:show_sandbox_datasets => true)
      end

      it "does not raise an error" do
        workspace.has_dataset?(destination).should be_true
        import.destination_dataset = destination
        expect {
          import.update_status(:passed)
        }.not_to raise_error
        workspace.has_dataset?(destination).should be_true
      end
    end
  end
end
