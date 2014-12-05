require 'spec_helper'

describe Hdfs::ImportsController do
  let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }
  let(:hdfs_dir) { hdfs_entries(:directory) }
  let(:hdfs_file) { hdfs_entries(:hdfs_file) }
  let(:upload) { uploads(:default) }
  let(:user) { upload.user }

  before { log_in user }

  describe '#create' do
    let(:params) do
      {
          :hdfs_data_source_id => hdfs_data_source.id,
          :file_id => hdfs_entry.id,
          :upload_id => upload.id
      }
    end

    context 'into a directory' do
      let(:hdfs_entry) { hdfs_dir }

      it 'creates an HdfsImport' do
        expect {
          post :create, params
          response.should be_success
        }.to change(HdfsImport, :count).by(1)

        last = HdfsImport.last
        last.user.should == user
        last.upload.should == upload
        last.hdfs_entry.should == hdfs_dir
      end

      it 'enqueues the import' do
        mock(QC.default_queue).enqueue_if_not_queued('Hdfs::ImportExecutor.run', is_a(Fixnum))
        post :create, params
      end

      it 'uses authorization' do
        mock(subject).authorize! :use, upload
        post :create, params
      end

      context 'when the current user is not the file uploader or admin' do
        let(:user) { users(:owner) }

        it 'is forbidden' do
          post :create, params
          response.should be_forbidden
        end
      end

      context 'with a file name' do
        it 'sets the file name' do
          post :create, params.merge(:file_name => 'custom_name')
          HdfsImport.last.file_name.should == 'custom_name'
        end
      end
    end

    context 'into a file' do
      let(:hdfs_entry) { hdfs_file }

      it 'returns 422' do
        post :create, params
        response.should be_unprocessable
        decoded_errors.fields.hdfs_entry.should have_key(:DIRECTORY_REQUIRED)
      end
    end
  end
end
