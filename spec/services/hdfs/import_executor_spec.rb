require 'spec_helper'

describe Hdfs::ImportExecutor do
  let(:hdfs_dir) { hdfs_entries(:directory) }
  let(:import) { FactoryGirl.create(:hdfs_import, :hdfs_entry => hdfs_dir) }

  describe '.run' do

    it 'creates an import executor with the specified import and runs it' do
      mock.proxy(described_class).new(import: import)
      any_instance_of(described_class) { |exe| mock(exe).run }
      described_class.run import.id
    end
  end

  describe '#run' do
    let(:exe) { described_class.new :import => import }

    context 'when the import succeeds' do
      before do
        any_instance_of Hdfs::QueryService do |qs|
          mock(qs).import_data is_a(String), is_a(java.io.FileInputStream)
        end
        mock(hdfs_dir).refresh
        mock(hdfs_dir.children).find_by_path(import.destination_path) { hdfs_entries(:hdfs_file) }
        exe
      end

      it 'imports the file in the hdfs data source of the hdfs entry' do
        exe.run
      end

      it 'destroys the import and upload' do
        expect {
          expect {
            exe.run
          }.to change(HdfsImport, :count).by(-1)
        }.to change(Upload, :count).by(-1)
      end

      it 'creates a success event' do
        expect {
          exe.run
        }.to change(Events::HdfsImportSuccess, :count).by(1)
        e = Events::Base.last
        e.actor.should be_present
        e.hdfs_entry.should be_present
        e.hdfs_data_source.should be_present
      end

      it 'creates a notification for the user' do
        expect {
          exe.run
        }.to change(Notification, :count).by(1)
        n = Notification.last
        n.event.should == Events::Base.last
        n.recipient.should == import.user
      end
    end

    context 'when the import fails' do
      before do
        any_instance_of(Hdfs::QueryService) { |qs| mock(qs).import_data.with_any_args { raise 'boom' } }
        exe
      end

      it 'destroys the import and upload' do
        expect {
          expect {
            exe.run
          }.to change(HdfsImport, :count).by(-1)
        }.to change(Upload, :count).by(-1)
      end

      it 'creates a failure event' do
        expect {
          exe.run
        }.to change(Events::HdfsImportFailed, :count).by(1)
        e = Events::Base.last
        e.actor.should be_present
        e.hdfs_data_source.should be_present
        e.file_name.should be_present
        e.error_message.should == 'boom'
      end

      it 'creates a notification for the user' do
        expect {
          exe.run
        }.to change(Notification, :count).by(1)
        n = Notification.last
        n.event.should == Events::Base.last
        n.recipient.should == import.user
      end
    end

    # context 'real hdfs', :hdfs_integration do
    #
    #
    # end
  end
end
