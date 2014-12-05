require 'spec_helper'

describe DataSources::MembersController do
  let(:admin) { users(:admin) }

  shared_examples_for :a_data_source do
    let(:data_source_owner) { data_source.owner }
    let(:shared_data_source) { data_sources(:shared) }
    let(:shared_owner) { shared_data_source.owner }
    let(:other_user) { FactoryGirl.create :user }

    describe "#index" do
      before do
        log_in data_source_owner
      end

      it_behaves_like "an action that requires authentication", :get, :index, :data_source_id => '-1'

      it "succeeds" do
        get :index, :data_source_id => data_source.to_param
        response.code.should == "200"
      end

      it "shows list of users" do
        get :index, :data_source_id => data_source.to_param
        decoded_response.length.should == data_source.accounts.size
      end

      it_behaves_like "a paginated list" do
        let(:params) { {:data_source_id => data_source.to_param} }
      end
    end

    describe "#create" do
      before do
        any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? { true } }
      end

      context "when admin" do
        before do
          log_in admin
        end

        it "fails for a shared account data source" do
          post :create, :data_source_id => shared_data_source.id, :account => {:db_username => "lenny", :db_password => "secret", :owner_id => shared_owner.id}
          response.should be_not_found
        end

        context "for an individual accounts data source" do
          it "get saved correctly" do
            post :create, :data_source_id => data_source.id, :account => {:db_username => "lenny", :db_password => "secret", :owner_id => admin.id}
            response.code.should == "201"
            rehydrated_account = DataSourceAccount.find(decoded_response.id)
            rehydrated_account.should be_present
            rehydrated_account.db_username.should == "lenny"
            rehydrated_account.db_password.should == "secret"
            rehydrated_account.owner.should == admin
            rehydrated_account.data_source.should == data_source
          end
        end
      end

      context "when data source owner" do
        before do
          log_in data_source_owner
        end

        it "fails for a shared accounts data source" do
          post :create, :data_source_id => shared_data_source.id, :account => {:db_username => "lenny", :db_password => "secret", :owner_id => shared_owner.id}
          response.should be_not_found
        end

        context "for an individual accounts data source" do
          it "get saved correctly" do
            post :create, :data_source_id => data_source.id, :account => {:db_username => "lenny", :db_password => "secret", :owner_id => data_source_owner.id}
            response.code.should == "201"
            rehydrated_account = DataSourceAccount.find(decoded_response.id)
            rehydrated_account.should be_present
            rehydrated_account.db_username.should == "lenny"
            rehydrated_account.db_password.should == "secret"
            rehydrated_account.owner.should == data_source_owner
            rehydrated_account.data_source.should == data_source
          end
        end
      end

      context "when other_user" do
        before do
          log_in other_user
        end

        it "fails for a shared accounts data source" do
          post :create, :data_source_id => shared_data_source.id, :account => {:db_username => "lenny", :db_password => "secret", :owner_id => other_user.id}
          response.should be_not_found
        end

        it "fails for an individual accounts data source" do
          post :create, :data_source_id => data_source.id, :account => {:db_username => "lenny", :db_password => "secret", :owner_id => other_user.id}
          response.should be_forbidden
        end
      end

      it "does not succeed when credentials are invalid" do
        log_in data_source_owner
        any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? {
          false
        } }
        post :create, :data_source_id => data_source.id, :account => {:db_username => "lenny", :db_password => "secret", :owner_id => data_source_owner.id}
        response.code.should == "422"
      end
    end

    describe "#update" do
      let(:account) { data_source.account_for_user(data_source_owner) }

      before do
        any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? { true } }
      end

      context "when admin" do
        before do
          log_in admin
        end

        it "succeeds" do
          put :update, :data_source_id => data_source.id, :id => account.id, :account => {:db_username => "changed", :db_password => "changed"}
          response.code.should == "200"

          decoded_response.db_username.should == "changed"
          decoded_response.owner.id.should == data_source_owner.id

          rehydrated_account = DataSourceAccount.find(decoded_response.id)
          rehydrated_account.db_password.should == "changed"
        end

        it "succeeds, even if data source is shared" do
          data_source.update_attribute :shared, true
          put :update, :data_source_id => data_source.id, :id => account.id, :account => {:db_username => "changed", :db_password => "changed"}
          response.code.should == "200"
        end
      end

      context "when data source owner" do
        before do
          log_in data_source_owner
        end

        it "succeeds for user's account" do
          put :update, :data_source_id => data_source.id, :id => account.id, :account => {:db_username => "changed", :db_password => "changed"}
          response.code.should == "200"

          decoded_response.db_username.should == "changed"
          decoded_response.owner.id.should == data_source_owner.id

          rehydrated_account = DataSourceAccount.find(decoded_response.id)
          rehydrated_account.db_password.should == "changed"
        end

        it "succeeds for user's account, even if data source is shared" do
          data_source.update_attribute :shared, true
          put :update, :data_source_id => data_source.id, :id => account.id, :account => {:db_username => "changed", :db_password => "changed"}
          response.code.should == "200"
        end

        it "succeeds for other's account" do
          account.update_attribute :owner, other_user
          put :update, :data_source_id => data_source.id, :id => account.id, :account => {:db_username => "changed", :db_password => "changed"}
          response.code.should == "200"

          decoded_response.db_username.should == "changed"
          decoded_response.owner.id.should == other_user.id

          rehydrated_account = DataSourceAccount.find(decoded_response.id)
          rehydrated_account.db_password.should == "changed"
        end
      end

      context "when other_user" do
        before do
          log_in other_user
        end

        context "someone else's account'" do
          it "fails" do
            put :update, :data_source_id => data_source.id, :id => account.id, :account => {:db_username => "changed", :db_password => "changed"}
            response.should be_forbidden
          end
        end

        context "his own account" do
          before do
            account.owner = other_user
            account.save!
          end

          it "fails" do
            put :update, :data_source_id => data_source.id, :id => account.id, :account => {:db_username => "changed", :db_password => "changed"}
            response.should be_forbidden
          end
        end
      end

      it "does not succeed when credentials are invalid" do
        log_in data_source_owner
        any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? { false } }
        put :update, :data_source_id => data_source.id, :id => account.id, :account => {:db_username => "changed", :db_password => "changed"}
        response.code.should == "422"
      end
    end

    describe "#destroy" do
      before do
        @other_user_account = FactoryGirl.build(:data_source_account, :data_source => data_source, :owner => other_user).tap { |a| a.save(:validate => false) }
      end

      context "when the current user is the data source's owner" do
        before do
          log_in data_source_owner
        end

        it "removes the given account" do
          data_source.accounts.find_by_owner_id(other_user.id).should_not be_nil
          delete :destroy, :data_source_id => data_source.id, :id => @other_user_account.id
          data_source.accounts.find_by_owner_id(other_user.id).should be_nil
        end

        it "succeeds" do
          delete :destroy, :data_source_id => data_source.id, :id => @other_user_account.id
          response.should be_ok
        end

        context "when there is no account for the given data source and user" do
          it "responds with 'not found'" do
            delete :destroy, :data_source_id => data_source.id, :id => 'not_an_id'
            response.should be_not_found
          end
        end
      end

      context "when the current user is not an admin nor the data source's owner" do
        before do
          log_in FactoryGirl.create(:user)
        end

        it "does not remove the account" do
          delete :destroy, :data_source_id => data_source.id, :id => @other_user_account.id
          data_source.accounts.find_by_owner_id(other_user.id).should_not be_nil
        end

        it "responds with 'forbidden'" do
          delete :destroy, :data_source_id => data_source.id, :id => @other_user_account.id
          response.should be_forbidden
        end
      end
    end
  end

  it_behaves_like :a_data_source do
    let(:data_source) { data_sources(:owners) }
  end

  it_behaves_like :a_data_source do
    let(:data_source) { data_sources(:oracle) }
  end

  describe "fixtures" do
    let(:data_source) { data_sources(:owners) }
    let(:data_source_owner) { data_source.owner }

    before do
      log_in data_source_owner
    end

    generate_fixture "dataSourceAccountSet.json" do
      get :index, :data_source_id => data_source.to_param
    end
  end
end
