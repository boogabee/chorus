require 'spec_helper'
require_relative 'helpers'

describe Events::HdfsImportFailed do
  extend EventHelpers

  let(:entry) { hdfs_entries(:directory) }
  let(:hdfs_data_source) { entry.hdfs_data_source }
  let(:actor) { hdfs_data_source.owner }

  subject { described_class.by(actor).add(:hdfs_data_source => hdfs_data_source, :file_name => 'file.csv', :error_message => 'Ahh!') }
  its(:additional_data) { should == {'error_message' => 'Ahh!', 'file_name' => 'file.csv'} }

  it_creates_activities_for { [actor, hdfs_data_source] }
  it_does_not_create_a_global_activity
end
