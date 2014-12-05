require 'spec_helper'

describe HdfsDataSourceAccess do
  let(:owner) { FactoryGirl.create(:user) }
  let(:hdfs_data_source) { FactoryGirl.create(:hdfs_data_source, :owner => owner) }

  subject do
    stub(controller = Object.new).current_user { current_user }
    described_class.new(controller)
  end

  describe "#edit?" do

    context "owner" do
      let(:current_user) { owner }

      it "allows access" do
        subject.can?(:edit, hdfs_data_source).should be_true
      end
    end

    context "regular user" do
      let(:current_user) { FactoryGirl.create(:user) }

      it "does not allow access" do
        user = FactoryGirl.create(:user)
        subject.can?(:edit, hdfs_data_source).should be_false
      end
    end
  end

  describe "#show?" do
    context "if the user has access to the hadoop data source" do
      let(:current_user) { users(:default) }

      it "allows access" do
        subject.can?(:show, hdfs_data_source).should be_true
      end
    end
  end

  describe "#show_contents?" do
    it "is always true" do
      subject.show_contents?('hamu sando').should be_true
    end
  end
end
