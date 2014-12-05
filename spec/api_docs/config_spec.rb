require 'spec_helper'

resource "Config" do
  let(:user) { users(:admin) }
  before do
    stub.proxy(License.instance).[](anything)
  end


  get "/config" do
    before do
      log_in user
    end

    example_request "Get server configuration" do
      status.should == 200
    end
  end

  get "/VERSION" do
    example_request "Get the version of Chorus" do
      status.should == 200
    end
  end
end
