require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Logout" do
  it "logs the user out" do
    login(users(:admin))
    wait_for_page_load
    find(".header .username a.label").click
    find(".menu.popup_username").should have_no_selector(".hidden")
    within '.menu.popup_username' do
      find("a", :text => "Sign Out", :visible => true).click
    end
    page.should have_content("Sign In")
    current_route.should == "login"
  end
end
