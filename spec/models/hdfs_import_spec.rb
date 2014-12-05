require 'spec_helper'

describe HdfsImport do

  describe 'validations' do
    it { should belong_to(:user) }
    it { should belong_to(:hdfs_entry) }
    it { should belong_to(:upload) }
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:hdfs_entry) }
    it { should validate_presence_of(:upload) }

    let(:hdfs_entry) { hdfs_entries(:hdfs_file) }
    let(:hdfs_directory) { hdfs_entries(:directory) }

    it 'requires the hdfs entry to be a directory' do
      invalid = FactoryGirl.build(:hdfs_import, :hdfs_entry => hdfs_entry)
      invalid.should have_error_on(:hdfs_entry, :DIRECTORY_REQUIRED)

      FactoryGirl.build(:hdfs_import, :hdfs_entry => hdfs_directory).should be_valid
    end

    describe 'destination uniqueness' do
      let(:stale_at) { nil }

      before do
        hdfs_directory.children.create!(
            {
                :path => "#{hdfs_directory.path}/collide.csv",
                :hdfs_data_source => hdfs_directory.hdfs_data_source,
                :stale_at => stale_at
            }, :without_protection => true
        )
      end

      it 'is not valid if a name collision exists on create' do
        import = HdfsImport.new(:hdfs_entry => hdfs_directory, :file_name => 'collide.csv')

        import.should have_error_on(:file_name).with_message(:TAKEN)
      end

      context 'when the colliding entry is stale' do
        let(:stale_at) { 5.minutes.ago }

        it 'does not consider stale entries when determining uniqueness' do
          import = HdfsImport.new(:hdfs_entry => hdfs_directory, :file_name => 'collide.csv')

          import.should_not have_error_on(:file_name)
        end
      end
    end
  end

  describe '#destination_file_name' do
    let(:import) { FactoryGirl.create(:hdfs_import, :hdfs_entry => hdfs_entries(:directory), :file_name => file_name) }

    context 'when it has a file_name' do
      let(:file_name) { '123.csv' }

      it 'returns that file_name' do
        import.destination_file_name.should == '123.csv'
      end
    end

    context 'when it does not have a file_name' do
      let(:file_name) { nil }

      it 'returns the file name of the upload' do
        import.destination_file_name.should == import.upload.contents_file_name
      end
    end
  end

end
