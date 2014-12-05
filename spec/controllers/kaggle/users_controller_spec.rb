require 'spec_helper'

describe Kaggle::UsersController do
  let(:user) { users(:owner) }

  before do
    log_in user
  end

  describe "#index" do
    include KaggleSpecHelpers

    before do
      stub(Kaggle::API).users(anything) do
        kaggle_users_api_result
      end
    end

    it_behaves_like "an action that requires authentication", :get, :index, :workspace_id => '-1'

    it "succeeds" do
      get :index, :workspace_id => '-1'
      response.code.should == "200"
    end

    it "shows list of users" do
      get :index, :workspace_id => '-1'
      decoded_response.length.should > 0
    end

    it "presents the kaggle users" do
      mock_present { |kaggle_users|
        kaggle_users.first.should be_a Kaggle::User
      }

      get :index, :workspace_id => '-1'
      response.should be_success
    end

    it "sorts by rank" do
      mock_present { | kaggle_users|
        kaggle_users.first.rank.should <= kaggle_users.second.rank
      }

      get :index, :workspace_id => '-1'
    end

    it "sends the filters to the KaggleApi.users method" do
      filters = ['i am a filter']
      mock(Kaggle::API).users(:filters => filters) { [] }
      get :index, :workspace_id => '-1', :filters => filters
    end

    context "when user fetching fails" do
      before do
        mock(Kaggle::API).users(anything) { raise Kaggle::API::NotReachable }
      end

      it "presents an error json" do
        get :index, :workspace_id => -1
        response.code.should == '422'
        decoded_errors.record.should == 'KAGGLE_API_UNREACHABLE'
      end
    end

    generate_fixture "kaggleUserSet.json" do
      get :index, :workspace_id => '-1'
    end
  end
end