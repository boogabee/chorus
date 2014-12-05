require 'spec_helper'

describe DataSources::AccountsController do
  let(:data_source) { data_sources(:owners) }
  let(:user) { users(:default) }
  let(:account) { data_source.account_for_user(user) }

  describe "#show" do
    let(:user) { users(:owner) }
    before do
      log_in user
    end

    it "returns the current_user's DataSourceAccount for the specified data source" do
      get :show, :data_source_id => data_source.to_param
      response.code.should == "200"
      decoded_response.id.should == account.id
      decoded_response.db_username.should == account.db_username
    end

    generate_fixture "dataSourceAccount.json" do
      get :show, :data_source_id => data_source.to_param
    end
  end

  describe "#create" do
    before do
      any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? { true } }
      log_in user
    end

    it "succeeds" do
      post :create, :data_source_id => data_source.id, :db_username => "lenny", :db_password => "secret"
      response.code.should == "201"

      decoded_response.db_username.should == "lenny"
      decoded_response.owner.id.should == user.id

      rehydrated_account = DataSourceAccount.find(decoded_response.id)
      rehydrated_account.db_password.should == "secret"
    end

    context "when the credentials are invalid" do
      before do
        any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? { false } }
      end

      it "fails" do
        post :create, :data_source_id => data_source.id, :db_username => "lenny", :db_password => "secret"
        response.code.should == '422'
      end
    end

    context "for a shared data source account" do
      let(:data_source) { FactoryGirl.create(:gpdb_data_source, {:shared => true, :owner => users(:default)}) }

      context "when you are the owner" do
        let(:user) { data_source.owner }

        it "succeeds" do
          post :create, :data_source_id => data_source.id, :db_username => "lenny", :db_password => "secret"
          response.code.should == "201"
        end
      end

      context "when you are an admin, but you are not the owner" do
        let(:user) { users(:admin) }

        it "succeeds" do
          account.db_username.should_not == "lenny"

          expect do
            post :create, :data_source_id => data_source.id, :db_username => "lenny", :db_password => "secret"
          end.not_to change(DataSourceAccount, :count)

          account.reload.db_username.should == "lenny"
        end
      end

      context "when you are not the owner, and not an admin" do
        let(:user) { users(:no_collaborators) }

        it "fails" do
          post :create, :data_source_id => data_source.id, :db_username => "lenny", :db_password => "secret"
          response.should be_forbidden
        end
      end
    end
  end

  describe "#update" do
    before do
      any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? { true } }
      log_in user
    end

    it "succeeds" do
      put :update, :data_source_id => data_source.id, :db_username => "changed", :db_password => "changed"
      response.code.should == "200"

      decoded_response.db_username.should == "changed"
      decoded_response.owner.id.should == user.id

      rehydrated_account = DataSourceAccount.find(decoded_response.id)
      rehydrated_account.db_password.should == "changed"
    end

    context "for a shared data_source" do
      let(:data_source) { data_sources(:shared) }
      before do
        data_source.update_attribute :shared, true
      end

      context "when you are the owner" do
        let(:user) { data_source.owner }

        it "succeeds" do
          put :update, :data_source_id => data_source.id, :db_username => "changed", :db_password => "changed"
          response.code.should == "200"
        end
      end

      context "when you are not the owner" do
        it "fails" do
          put :update, :data_source_id => data_source.id, :db_username => "changed", :db_password => "changed"
          response.should be_forbidden
        end
      end
    end

    context "when credentials are invalid " do
      before do
        any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? { false } }
      end

      it "fails" do
        put :update, :data_source_id => data_source.id, :db_username => "changed", :db_password => "changed"
        response.code.should == '422'
      end
    end
  end

  describe "#destroy" do
    before { log_in user }

    context "of an unshared account" do
      let(:user) { users(:owner) }

      it "succeeds" do
        delete :destroy, :data_source_id => data_source.id
        response.should be_success
      end

      it "deletes the current users account for this data_source" do
        DataSourceAccount.find_by_data_source_id_and_owner_id(data_source.id, user.id).should_not be_nil
        delete :destroy, :data_source_id => data_source.id
        DataSourceAccount.find_by_data_source_id_and_owner_id(data_source.id, user.id).should be_nil
      end
    end

    context "of a shared account" do
      let(:data_source) { data_sources(:shared) }

      context "when the current user is an admin" do
        let(:user) { users(:admin) }
        it "does not delete the owner's account" do
          lambda { delete :destroy, :data_source_id => data_source.id }.should_not change { DataSourceAccount.count }
          response.code.should == "404"
        end
      end

      context "when the current user is not the owner and not an admin" do
        it "does not delete the shared account" do
          lambda { delete :destroy, :data_source_id => data_source.id }.should_not change { DataSourceAccount.count }
          response.code.should == "404"
        end
      end
    end
  end
end
