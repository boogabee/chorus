require 'spec_helper'

describe "resources which require authentication" do
  let!(:user) { users(:default) }

  context "after the user has logged in" do
    before do
      post "/sessions", :session => {:username => user.username, :password => FixtureBuilder.password}
      response.should be_success
    end

    it "shows the resource" do
      get "/users"
      response.should be_success
    end

    context "then logged out" do
      before do
        delete "/sessions"
      end

      it "refuses to show the resource" do
        get "/users"
        response.code.should == "401"
      end
    end

    it "should include user id in logs" do
      user_id_proc = Chorus::Application.config.log_tags[1]
      stub.proxy(user_id_proc).call.with_any_args do |log_tag|
        log_tag.should == "user_id:#{user.id}"
      end
      get "/users"
    end
  end

  context "when the user has never logged in" do
    it "refuses to show the resource" do
      get "/users"
      response.code.should == "401"
    end

    it "should include not_logged_in in logs" do
      user_id_proc = Chorus::Application.config.log_tags[1]
      stub.proxy(user_id_proc).call.with_any_args do |log_tag|
        log_tag.should == "not_logged_in"
      end
      get "/users"
    end
  end

  context "when user has a bogus session_id" do
    before do
      post "/sessions", :session => {:username => user.username, :password => FixtureBuilder.password}
      response.should be_success
      Session.last.delete
    end

    it "should include not_logged_in in logs" do
      user_id_proc = Chorus::Application.config.log_tags[1]
      stub.proxy(user_id_proc).call.with_any_args do |log_tag|
        log_tag.should == "not_logged_in"
      end
      get "/users"
    end
  end
end
