require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Insights" do
   it 'clicks on the insights link on the home page' do
      login(users(:owner))
      within '.dashboard_activity_list_header' do
        select_item('select.activities_filter', 'only_insights')
        find('.title').should have_content('Recent Activity'.upcase)
      end
  end

  it "creates an insight" do
    login(users(:owner))

    workspace_id = workspaces(:public).id
    visit("#/workspaces/#{workspace_id}")

    workspace_name = workspaces(:public).name
    find("#page_sub_header").should have_content(workspace_name)

    click_link "Add an Insight"

    within_modal do
      set_cleditor_value("body", "This is adding an Insight")
      click_button "Add Insight"
    end
  end
end
