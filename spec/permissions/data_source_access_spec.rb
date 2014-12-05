require "spec_helper"

describe DataSourceAccess do
  let(:data_source) { data_sources(:owners) }
  let(:owner) { data_source.owner }
  let(:data_source_access) {
    controller = DataSourcesController.new
    stub(controller).current_user { @user }
    DataSourceAccess.new(controller)
  }

  describe ".data_sources_for" do
    it "returns limited data sources" do
      @user = users(:admin)
      mock(DataSource).accessible_to(@user)

      described_class.data_sources_for(@user)
    end
  end

  describe "#edit?" do
    it "prevents regular users from editing" do
      @user = users(:the_collaborator)
      data_source_access.can?(:edit, data_source).should be_false
    end

    it "allows owners to edit" do
      @user = data_source.owner
      data_source_access.can?(:edit, data_source).should be_true
    end

    it "allows admins to edit" do
      @user = users(:admin)
      data_source_access.can?(:edit, data_source).should be_true
    end
  end

  describe "#show?" do
    it "allows everyone" do
      data_source_access.can?(:show, data_source).should be_true
    end
  end

  describe "show_contents?" do
    context "for public data sources" do
      it "shows for everybody, including non-owner, non-admin users" do
        @user = users(:no_collaborators)
        data_source = data_sources(:shared)
        data_source.shared.should be_true
        data_source_access.can?(:show_contents, data_source).should be_true
      end
    end

    context "for private data sources" do
      before do
        data_source.shared.should be_false
      end

      it "allows members to show (which includes owner)" do
        @user = users(:the_collaborator)
        data_source.account_for_user(@user).should_not be_nil
        data_source_access.can?(:show_contents, data_source).should be_true
      end

      it "prevents non-members from showing" do
        @user = users(:no_collaborators)
        data_source.account_for_user(@user).should be_nil
        data_source_access.can?(:show_contents, data_source).should be_false
      end

      it "prevents non-member admins from showing" do
        @user = users(:admin)
        data_source.account_for_user(@user).should be_nil
        data_source_access.can?(:show_contents, data_source).should be_false
      end
    end
  end
end