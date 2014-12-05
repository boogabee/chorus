require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Workfiles" do
  let(:workspace) { workspaces(:public) }
  let(:user) { users(:admin) }

  describe "add a workfile" do
    it "uploads a workfile from the local system" do
      login(user)
      visit("#/workspaces/#{workspace.id}")

      click_link "Work Files"
      click_link("Upload a File")
      within_modal do
        attach_file("workfile[versions_attributes][0][contents]", File.join(File.dirname(__FILE__), '../fixtures/some.txt'))
        click_button("Upload File")
      end
      find('.sub_nav a', :text => "Work Files".upcase).click
      page.should have_content "some.txt"
      workspace.workfiles.find_by_file_name("some.txt").should_not be_nil
    end
  end

  describe "Deleting workfiles" do
    let(:workfile) { workfiles(:'sql.sql') }

    it "deletes an uploaded file from the show page" do
      login(user)
      visit("#/workspaces/#{workspace.id}")

      click_link "Work Files"
      click_link workfile.file_name

      within '.workfile_sidebar .actions > ul' do
        click_link 'Delete'
      end

      within_modal do
        click_button 'Delete'
      end
      page.should_not have_content(workfile.file_name)
      Workfile.find_by_id(workfile.id).should be_nil
    end
  end

  describe "workfiles list page" do
    let(:workfile_first_by_date) { workspace.workfiles.order(:user_modified_at).last }
    let(:workfile_last_by_date) { workspace.workfiles.order(:user_modified_at).first }

    describe "Lists the work files" do
      before(:each) do
        login(user)
        visit("#/workspaces/#{workspace.id}/workfiles")
      end

      it "Lists the work files by updated date when selected" do
        wait_for_page_load
        find('a', :text => "Alphabetically", :visible => true).click
        find('a', :text => "By Date", :visible => true).click
        sleep 2 # im sorry - how to know when page re-renders without sidebar?
        workfiles = page.all(".workfile_item")
        workfiles.first.text.should include workfile_first_by_date.file_name
        workfiles.last.text.should include workfile_last_by_date.file_name
      end
    end
  end

  describe "editing a workfile", :greenplum_integration do
    let(:workspace) { workspaces(:real) }
    let(:user) { users(:admin) }
    let(:file) { File.open(Rails.root.join('spec', 'fixtures', 'workfile.sql')) }
    let(:workfile) { FactoryGirl.create :chorus_workfile, :workspace => workspace, :file_name => 'sqley.sql', :execution_schema => workspace.sandbox, :owner => user }

    before do
      FactoryGirl.create :workfile_version, :workfile => workfile, :owner => user, :modifier => user, :contents => file
      login(user)
      visit("#/workspaces/#{workspace.id}/workfiles/#{workfile.id}")
    end

    def type_workfile_contents(text)
      page.execute_script "chorus.page.mainContent.content.textContent.editor.setValue('#{text}')"
    end

    def get_workfile_contents
      page.execute_script "return chorus.page.mainContent.content.textContent.editor.getValue()"
    end

    describe "changing the schema" do
      it "should retain any pre-existing edits" do
        page.should have_css ".CodeMirror-lines"
        type_workfile_contents "fooey"
        click_link "Change"
        within_modal do
          within ".schema .select_container" do
            page.should have_content(workspace.sandbox.name)
          end
          click_button "Save Search Path"
        end
        get_workfile_contents.should == "fooey"
      end
    end

    describe "if you don't have a valid data source account for the schema" do
      let(:user) { users(:restricted_user) }
      it "should display an 'add credentials' link in the sidebar" do
        page.find('.data_tab').should have_text("add your credentials")
      end
    end
  end
end
