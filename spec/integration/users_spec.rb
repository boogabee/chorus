require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Users" do
  let(:admin) { users(:admin) }
  let(:user) { users(:not_a_member) }
  let(:workspace_owner) { users(:no_collaborators) }

  before do
    login(admin)
  end

  describe "creating a user" do

    it "creates a user and saves their information" do
      visit "/#/users/new"
      fill_in 'firstName', :with => "James"
      fill_in 'lastName', :with => "Bond"
      fill_in 'username', :with => "bondjamesbond007"
      fill_in 'email', :with => "new_user@example.com"
      fill_in 'password', :with => "secret"
      fill_in 'passwordConfirmation', :with => "secret"
      fill_in 'title', :with => "dev"
      fill_in 'dept', :with => "chorus"
      fill_in 'notes', :with => "This is a test user."
      click_button "Add this Person"

      within ".main_content" do
        click_link "James Bond"
        find("h1").should have_content("James Bond")
      end
    end

    it "user can upload a user image" do
      visit "#/users"
      within ".content .list" do
        click_link("#{admin.first_name} #{admin.last_name}")
      end
      click_link "Edit Profile"
      attach_file("image_upload_input", File.join(File.dirname(__FILE__), '../fixtures/User.png'))
      click_button "Save Changes"
      page.should have_selector(".breadcrumb:contains('#{admin.first_name}')")
      admin.reload.image.original_filename.should == 'User.png'
    end
  end

  describe "changing the password for a user" do
    it "allows a user to change the password" do
      visit "#/users"
      within ".content .list" do
        click_link("#{admin.first_name} #{admin.last_name}")
      end
      click_link "Change Password"
      page.should have_content("Change Password")

      within_modal do
        fill_in 'password', :with => "secret123"
        fill_in 'passwordConfirmation', :with => "secret123"
        click_button "Change Password"
      end

      logout
      login(admin, 'secret123')
    end
  end

  describe "promoting a user to administrator" do
    it "allows the user to edit other admin accounts" do
      visit "#/users"
      within ".content .list" do
        click_link "#{user.first_name} #{user.last_name}"
      end
      click_link "Edit Profile"
      check "Make this person an administrator"
      click_button "Save Changes"
      find('a', :text => "Edit Profile")

      logout
      login(user)
      visit "#/users"
      within ".content .list" do
        click_link "#{admin.first_name} #{admin.last_name}"
      end
      page.should have_link("Edit Profile")
    end
  end

  describe "deleting a user" do
    it "deletes a user" do
      visit "#/users"
      within ".content .list" do
        click_link "#{user.first_name} #{user.last_name}"
      end
      click_link "Delete Person"
      click_button "Delete profile"
      within ".content .list" do
        page.should_not have_content("#{user.first_name} #{user.last_name}")
      end
    end
  end
end
