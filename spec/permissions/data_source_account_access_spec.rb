require "spec_helper"

describe DataSourceAccountAccess do
  let(:data_source_account_access) do
    stub(controller = Object.new).current_user { current_user }
    DataSourceAccountAccess.new(controller)
  end

  describe "update?" do
    let(:data_source_account) { data_source.account_for_user(current_user) }
    let(:data_source) { FactoryGirl.create(:gpdb_data_source, :shared => true, :owner => users(:default)) }

    context "for the owner" do
      let(:current_user) { data_source.owner }

      it "is allowed" do
        data_source_account_access.can?(:update, data_source_account).should be_true
      end
    end

    context "for the admin" do
      let(:current_user) { users(:admin) }

      it "is allowed" do
        data_source_account_access.can?(:update, data_source_account).should be_true
      end
    end

    context "for others" do
      let(:current_user) { users(:no_collaborators) }

      it "is not allowed" do
        data_source_account_access.can?(:update, data_source_account).should be_false
      end
    end
  end
end