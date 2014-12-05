require 'spec_helper'

describe "generating some test data for javascript fixture tests" do
  it "generates", :fixture do
    save_fixture "test/withOverrides.json", {:response => {:id => "1", :first_name => "ron"} }
    save_fixture "test/noOverrides.json", {:response => {:id => "1", :first_name => "dan"} }
  end
end