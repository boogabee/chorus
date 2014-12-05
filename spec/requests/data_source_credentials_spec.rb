require 'spec_helper'

describe "data source credentials" do
  let(:user) { users(:owner) }
  let(:data_source) { data_sources(:owners) }

  before do
    stub(License.instance).workflow_enabled? { true }
    post "/sessions", :session => { :username => user.username, :password => FixtureBuilder.password }
  end

  context "when request is from localhost" do
    it "works" do
      get "/data_sources/#{data_source.id}/credentials"

      response.should be_success
    end
  end

  context "when request is not from localhost" do
    it "doesn't work" do
      get "/data_sources/#{data_source.id}/credentials", {}, {'REMOTE_ADDR' => '86.75.30.9'}
      response.should be_not_found
    end
  end
end
