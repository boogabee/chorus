require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Managing workspace members" do

  before do
    login(users(:owner))
  end

  let(:private_workspace) { workspaces(:private) }
  let(:user) { users(:default) }

  it "Updates the workspace members list" do
    visit("#/workspaces/#{private_workspace.id}")
    click_link "Add or Edit Members"
    within ".available li[data-id='#{user.id}']" do
      click_link "Add"
    end
    click_button "Save Changes"

    logout
    login(user)
    visit("#/workspaces/#{private_workspace.id}")
    page.should have_content("Summary".upcase)
    page.should_not have_link("Add or Edit Members")
  end
end
