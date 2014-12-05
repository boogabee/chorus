require 'spec_helper'

describe HdfsEntryAccess do
  let(:context) { Object.new }
  let(:access) { HdfsEntryAccess.new(context)}
  let(:hdfs_entry) { hdfs_entries(:hdfs_file) }

  before do
    stub(context).current_user { user }
  end

  describe "#show?" do
    context "if the user has access to the hdfs_entry's data source" do
      let(:user) { users(:the_collaborator) }

      it "allows access" do
        access.can?(:show, hdfs_entry).should be_true
      end
    end

    context "if the user does not have access to the hdfs_entry's data source" do
      let(:user) { users(:the_collaborator) }

      before do
        any_instance_of(HdfsDataSourceAccess) do |instance|
          stub(instance).can? :show, hdfs_entry.hdfs_data_source { false }
        end
      end

      it "prevents access" do
        access.can?(:show, hdfs_entry).should be_false
      end
    end
  end
end