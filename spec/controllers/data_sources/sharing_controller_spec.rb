require 'spec_helper'

describe DataSources::SharingController do
  shared_examples_for "a shareable data source" do
    before { log_in owner }

    describe "#create" do
      it "sets the shared attribute on an unshared data source" do
        data_source.update_attributes(:shared => false)
        post :create, :data_source_id => data_source.to_param
        decoded_response.shared.should be_true
      end

      it "keeps the shared attribute on a shared data source" do
        data_source.update_attributes(:shared => true)
        post :create, :data_source_id => data_source.to_param
        decoded_response.shared.should be_true
      end

      it "deletes accounts other than those belonging to the data source owner" do
        other_account = data_source.account_for_user(users(:the_collaborator))

        post :create, :data_source_id => data_source.to_param

        owner_account.reload.should be_present
        DataSourceAccount.where(:id => other_account.id).exists?.should be_false
      end

      it "rejects non-owners" do
        log_in user
        post :create, :data_source_id => data_source.to_param
        response.should be_forbidden
      end

      it "rejects non-owners of shared accounts" do
        log_in user
        data_source.update_attributes(:shared => true)

        post :create, :data_source_id => data_source.to_param
        response.should be_forbidden
      end
    end

    describe "#destroy" do
      it "removes the shared attribute from a shared data source" do
        data_source.update_attributes(:shared => true)
        delete :destroy, :data_source_id => data_source.to_param
        decoded_response.shared.should_not be_true
      end

      it "keeps the unshared attribute on an unshared data source" do
        data_source.update_attributes(:shared => false)
        delete :destroy, :data_source_id => data_source.to_param
        decoded_response.shared.should_not be_true
      end

      it "rejects non-owners" do
        log_in user
        delete :destroy, :data_source_id => data_source.to_param
        response.should be_forbidden
      end

      it "rejects non-owners of shared accounts" do
        log_in user
        data_source.update_attributes(:shared => true)

        delete :destroy, :data_source_id => data_source.to_param
        response.should be_forbidden
      end
    end
  end

  context "with a gpdb data source" do
    it_should_behave_like "a shareable data source" do
      let(:data_source) { data_sources(:owners) }
      let(:owner_account) { data_source.owner_account }
      let(:owner) { users(:owner) }
      let(:user) { users(:default) }
    end
  end

  context "with an oracle data source" do
    it_should_behave_like "a shareable data source" do
      let(:data_source) { data_sources(:oracle) }
      let(:owner_account) { data_source.owner_account }
      let(:owner) { users(:owner) }
      let(:user) { users(:default) }
    end
  end
end
