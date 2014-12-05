require 'spec_helper'
require 'timecop'

describe SessionsController do
  describe "#create" do
    let(:user) { users(:admin) }
    let(:params) { {:username => user.username, :password => FixtureBuilder.password} }

    describe "with the correct credentials" do
      it "succeeds" do
        post :create, params
        response.code.should == "201"
      end

      it "creates a new session" do
        expect { post :create, params }.to change(Session, :count).by(1)
        Session.last.user.should == user
      end

      it "adds the session_id to the session" do
        expect { post :create, params }.to change(Session, :count).by(1)
        session[:chorus_session_id].should == Session.last.session_id
      end

      it "should present the session" do
        mock_present do |model|
          model.should be_a Session
          model.user.should == user
        end
        post :create, params
      end
    end

    context "with correct credentials for a deleted user" do
      let(:user) {users :evil_admin}
      before do
        user.destroy
        post :create, params
      end

      it "fails with response code 401" do
        response.code.should == "401"
      end
    end

    describe "with incorrect credentials" do
      let(:params) { {:username => user.username, :password => 'badpassword'} }
      before do
        post :create, params
      end

      it "fails with response code 401" do
        response.code.should == "401"
      end

      it "includes details of invalid credentials" do
        decoded_errors.fields.username_or_password.INVALID.should == {}
      end
    end

    context 'the last system status indicates expired' do
      before do
        FactoryGirl.create(:system_status, :expired => true)
      end

      it 'presents license expired errors' do
        post :create, params
        response.code.should == '503'
      end
    end
  end

  describe "#show" do
    context "When logged in" do
      let(:user) { users(:default) }

      before do
        log_in user
        get :show
      end

      it "should present the session" do
        mock_present do |model|
          model.should be_a Session
          model.user.should == user
        end
        get :show
        response.code.should == "200"
      end

      generate_fixture "session.json" do
        get :show
      end
    end

    context "when not logged in" do
      before do
        get :show
      end
      it "returns 401" do
        response.code.should == "401"
      end
    end
  end

  describe "#destroy" do
    it 'returns a new csrf token' do
      initial_token = subject.send(:form_authenticity_token)

      delete :destroy
      response.should be_success

      new_token = subject.send(:form_authenticity_token)
      new_token.should_not == initial_token
      decoded = JSON.parse(response.body)
      decoded['csrf_token'].should == new_token
    end

    it 'clears the session' do
      session_object = log_in users(:owner)
      delete :destroy
      response.should be_success
      session[:user_id].should_not be_present
      session[:expires_at].should_not be_present
      Session.find_by_id(session_object.id).should be_nil
    end
  end
end
