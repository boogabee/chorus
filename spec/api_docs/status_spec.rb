require 'spec_helper'

resource "Status" do
  get "/status" do
    example_request " Check if the Chorus server is running" do
      status.should == 200
    end
  end
end