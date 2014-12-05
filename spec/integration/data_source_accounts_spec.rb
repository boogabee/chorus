require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Data Source Accounts" do
  let(:data_source) { GreenplumIntegration.real_data_source }
  let(:no_access_user) { users(:default) }
  let(:owner) { users(:admin)}

  before do
    login(owner)
    visit("#/data_sources/")
    find(".data_source_item", :text => data_source.name).click
    within '.account_info' do
      click_link "Edit"
    end
  end

  after do
    click_button "Close Window"
    logout

    login(no_access_user)
    visit("#/data_sources/")
    click_link data_source.name
    within ".content_details" do
      find(:css, '.count').text.should =~ /.*Databases/
    end
  end

  it "Adds new data source account" do
    click_button "Add Account"
    select_item('#select_new_data_source_account_owner', no_access_user.id)
    within "li.editing" do
      fill_in "dbUsername", :with => GreenplumIntegration.username
      fill_in "dbPassword", :with => GreenplumIntegration.password
      click_link "Save Changes"
    end
  end

  it "Updates a Data Source to have a shared account" do
    click_link "Switch to single shared account"
    click_button "Enable shared account"
  end
end