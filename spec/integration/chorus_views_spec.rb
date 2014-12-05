require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Chorus Views", :greenplum_integration do
  describe "Create" do

    let(:workspace) { workspaces(:gpdb_workspace) }
    let(:dataset) { workspace.sandbox.datasets.where(:name => "base_table1").first }

    it "creates a new chorus view" do
      login(users(:admin))
      visit("#/workspaces/#{workspace.id}/datasets/#{dataset.id}")
      page.should have_button("Derive a Chorus View")
      find(".list li.selected").click
      click_button "Derive a Chorus View"
      click_button "Verify Chorus View"
      within_modal do
        click_button "Create Chorus View"
        fill_in 'objectName', :with => "New_Chorus_View"
        click_button "Create Chorus View"
      end
      workspace.chorus_views.find_by_name("New_Chorus_View").should_not be_nil
    end
  end

  describe "editing" do
    let(:chorus_view) { datasets(:executable_chorus_view) }
    let(:workspace) { chorus_view.workspace }
    let(:user) { users(:admin) }

    def get_chorus_view_editable_contents
      page.execute_script "return chorus.page.mainContent.content.editor.getValue()"
    end

    before do
      login(user)
      visit("#/workspaces/#{workspace.id}/chorus_views/#{chorus_view.id}")
      click_on "Edit"
      page.should have_content("Edit the query and save your changes")
      get_chorus_view_editable_contents.should == chorus_view.query
    end

    it "allows the user cancel editing" do
      within ".dataset_content_details" do
        within ".edit_chorus_view" do
          click_on "Cancel"
        end

        page.should have_content("SQL: #{chorus_view.query}")
      end
    end
  end
end