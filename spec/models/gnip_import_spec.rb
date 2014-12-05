require 'spec_helper'

describe GnipImport do
  let(:import) { imports(:gnip) }
  let(:user) { users(:owner) }

  describe 'associations' do
    it { should belong_to(:scoped_workspace) }
  end

  describe 'validations' do
    let(:import) { FactoryGirl.build(:gnip_import, :workspace => workspace, :user => user) }
    let(:workspace) { workspaces(:public) }
    let(:table_exists) { false }

    before do
      connection = Object.new
      stub(connection).table_exists?(import.to_table) { table_exists }
      stub(workspace.sandbox).connect_as(anything) { connection }
    end

    context "when the to_table already exists" do
      let(:table_exists) { true }

      it "is invalid" do
        import.should have_error_on(:base).with_message(:table_exists)
      end
    end
  end

  describe 'creating' do
    let(:workspace) { workspaces(:public) }
    let(:import) { FactoryGirl.build(:gnip_import, :to_table => "the_new_table", :workspace => workspace, :user => user) }

    before do
      connection = Object.new
      stub(workspace.sandbox).connect_as(anything) { connection }
      stub(connection).table_exists?(anything) { false }
    end

    it 'creates a GnipStreamImportCreated event' do
      expect {
        import.save!(:validate => false)
      }.to change(Events::GnipStreamImportCreated, :count).by(1)

      event = Events::GnipStreamImportCreated.last
      event.actor.should == user
      event.dataset.should be_nil
      event.workspace.should == workspace
      event.destination_table.should == 'the_new_table'
    end
  end

  describe '#create_passed_event_and_notification' do
    it 'creates a GnipStreamImportSuccess event' do
      expect {
        import.create_passed_event_and_notification
      }.to change(Events::GnipStreamImportSuccess, :count).by(1)

      event = Events::GnipStreamImportSuccess.last
      event.actor.should == import.user
      event.workspace.should == import.workspace
    end

    it 'creates a notification for the import creator' do
      expect {
        import.create_passed_event_and_notification
      }.to change(Notification, :count).by(1)
      notification = Notification.last
      notification.recipient_id.should == import.user_id
      notification.event_id.should == Events::GnipStreamImportSuccess.last.id
    end
  end

  describe '#create_failed_event_and_notification' do
    it 'creates a FileImportFailed event' do
      expect {
        import.create_failed_event_and_notification("message")
      }.to change(Events::GnipStreamImportFailed, :count).by(1)
      event = Events::GnipStreamImportFailed.last

      event.actor.should == user
      event.destination_table.should == import.to_table
      event.workspace.should == import.workspace
      event.error_message.should == "message"
    end

    it 'creates a notification for the import creator' do
      expect {
        import.create_failed_event_and_notification("message")
      }.to change(Notification, :count).by(1)
      notification = Notification.last
      notification.recipient_id.should == import.user_id
      notification.event_id.should == Events::GnipStreamImportFailed.last.id
    end
  end

  describe "copier_class" do
    it "should be GnipCopier" do
      import.copier_class.should == GnipCopier
    end
  end
end