require 'spec_helper'

resource "Import Console" do
  let(:user) { users(:admin) }

  before do
    log_in user
  end

  before do
    # remove fixtures to avoid database connection
    Import.delete_all
  end

  get "/import_console/imports" do
    example_request "Show the import console" do
      status.should == 200
    end
  end
end