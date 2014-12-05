require 'spec_helper'

describe CsvImport do
  let(:import) { imports(:csv) }
  let(:user) { import.user }

  describe 'associations' do
    it { should belong_to(:scoped_workspace) }
  end

  describe 'validations' do
    let(:import) { FactoryGirl.build(:csv_import, options.merge(:workspace => workspace, :user => user)) }
    let(:workspace) { workspaces(:public) }
    let(:user) { users(:owner) }
    let(:table_exists) { false }
    let(:options) { {} }

    before do
      connection = Object.new
      stub(connection).table_exists?(import.to_table) { table_exists }
      stub(workspace.sandbox).connect_as(anything) { connection }
    end

    context "when creating a 'new table' import" do
      context "when the to_table already exists" do
        let(:table_exists) { true }

        it "is invalid" do
          import.should have_error_on(:base).with_message(:table_exists)
        end
      end

      context "when the column_names includes duplicates" do
        let(:options) { { :csv_file => FactoryGirl.create(:csv_file, :column_names => %w(tacos chips tacos burritos chips))} }

        it "is invalid" do
          import.should have_error_on(:column_names).with_message(:duplicates).with_options(:dupes => "tacos, chips")
        end
      end
    end
  end

  describe 'creating' do
    let(:workspace) { workspaces(:public) }

    before do
      connection = Object.new
      stub(workspace.sandbox).connect_as(anything) { connection }
      stub(connection).table_exists?(anything) { false }
    end

    it 'creates a FileImportCreated event' do
      import = CsvImport.new
      import.to_table = 'the_new_table'
      import.workspace = workspace
      import.user = user
      import.file_name = "foo.docx"
      expect {
        import.save!(:validate => false)
      }.to change(Events::FileImportCreated, :count).by(1)

      event = Events::FileImportCreated.last
      event.actor.should == user
      event.dataset.should be_nil
      event.import_type.should == 'file'
      event.file_name.should == "foo.docx"
      event.workspace.should == workspace
      event.destination_table.should == 'the_new_table'
    end

    it "enqueues an import task" do
      mock(QC.default_queue).enqueue_if_not_queued("ImportExecutor.run", numeric)
      FactoryGirl.create(:csv_import, :workspace => workspace, :destination_dataset => nil)
    end
  end


  describe '#create_passed_event_and_notification' do
    it 'creates a FileImportSuccess event' do
      expect {
        import.create_passed_event_and_notification
      }.to change(Events::FileImportSuccess, :count).by(1)

      event = Events::FileImportSuccess.last
      event.actor.should == import.user
      event.workspace.should == import.workspace
      event.file_name.should == import.file_name
      event.import_type.should == 'file'
    end

    it 'creates a notification for the import creator' do
      expect {
        import.create_passed_event_and_notification
      }.to change(Notification, :count).by(1)
      notification = Notification.last
      notification.recipient_id.should == import.user_id
      notification.event_id.should == Events::FileImportSuccess.last.id
    end
  end

  describe '#create_failed_event_and_notification' do
    it 'creates a FileImportFailed event' do
      expect {
        import.create_failed_event_and_notification("message")
      }.to change(Events::FileImportFailed, :count).by(1)
      event = Events::FileImportFailed.last

      event.actor.should == user
      event.destination_table.should == import.to_table
      event.workspace.should == import.workspace
      event.file_name.should == import.file_name
      event.import_type.should == 'file'
      event.error_message.should == "message"
    end

    it 'creates a notification for the import creator' do
      expect {
        import.create_failed_event_and_notification("message")
      }.to change(Notification, :count).by(1)
      notification = Notification.last
      notification.recipient_id.should == import.user_id
      notification.event_id.should == Events::FileImportFailed.last.id
    end
  end

  describe "copier_class" do
    it "should be CsvCopier" do
      import.copier_class.should == CsvCopier
    end
  end
end