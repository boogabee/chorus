require File.join(File.dirname(__FILE__), 'spec_helper')

describe "500 Internal Server Error" do
  let(:workspace) { workspaces(:public) }

  context "uploading a workfile and deleting it from the server" do
    it "causes a 500 error" do
      login(users(:admin))
      visit("#/workspaces/#{workspace.id}")

      click_link "Work Files"
      click_link("Upload a File")

      within_modal do
        attach_file("workfile[versions_attributes][0][contents]", File.join(File.dirname(__FILE__), '../fixtures/some.txt'))
        click_button("Upload File")
      end

      find('.sub_nav a', :text => "Work Files".upcase).click
      page.should have_content "some.txt"

      workfile_version = workspace.workfiles.find_by_file_name("some.txt").latest_workfile_version
      path = workfile_version.contents.path
      File.delete path
      File.exists?(path).should be_false

      wait_for_page_load
      click_link "some.txt"
      page.should have_no_content("some.txt")

      expect {
        Capybara.reset_sessions!
      }.to raise_error(StandardError, "No such file or directory - #{path}")
    end
  end
end
