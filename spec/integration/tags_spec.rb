require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'listing all tags' do
  let(:user) { users(:owner) }
  let(:workfile) { workfiles(:public) }
  before do
    login(user)
    workfile.tag_list = %w{foo bar baz}
    visit "#/tags"
  end

  it "shows the tags" do
    %w(foo bar baz).each do |name|
      page.should have_link(name)
    end
  end

  it "renames a specific tag" do
    find('li', :text => 'foo').click
    click_on "Rename Tag"
    within_modal do
      find("input").set("hello")
      click_on "Rename Tag"
    end

    find('li', :text => 'hello').should have_link("hello")

    # check that tag is persisted
    visit "#/"

    visit "#/tags"
    page.should have_link("hello")
  end
end

describe 'add a tag' do

  let(:workfile) {workfiles(:public)}
  let(:workspace) {workfile.workspace}

  before do
    login(users(:admin))
  end

  describe 'to a workspace' do
    xit 'adds the tag in the workspace summary page' do
      visit("#/workspaces/#{workspace.id}")

      within '.content_header' do
        page.should have_selector("#tag_editor", :visible => true)
        fill_in 'tag_editor', :with => 'new_tag'
        find('.tag_editor').native.send_keys(:return)

        fill_in 'tag_editor', :with => 'comma_separated_tag_1, comma_separated_tag_2'
        find('.tag_editor').native.send_keys(:return)
      end

      workspace.reload
      workspace.tags.first.name.should == "new_tag"
    end
  end

  describe 'to a workfile' do

    xit 'adds the tags in the workfile show page' do
      visit("#/workspaces/#{workspace.id}/workfiles/#{workfile.id}")

      within '.content' do
        page.should have_no_selector(".loading_section")
      end

      within '.content_header' do
        page.should have_selector("#tag_editor", :visible => true)
        fill_in 'tag_editor', :with => 'new_tag'
        find('.tag_editor').native.send_keys(:return)

        fill_in 'tag_editor', :with => 'comma_separated_tag_1,comma_separated_tag_2'
        find('.tag_editor').native.send_keys(:return)
      end

      visit("#/workspaces/#{workspace.id}/workfiles/#{workfile.id}")
      within '.content_header' do
        page.should have_content 'new_tag'

        page.should have_content 'comma_separated_tag_1'
        page.should have_content 'comma_separated_tag_2'
        page.should_not have_content 'comma_separated_tag_1,comma_separated_tag_2'
      end
    end

    it 'adds tags to multiple work files' do
      visit("#/workspaces/#{workspace.id}/workfiles")
      within ".content" do
        find('a', :text => workfile.file_name)
      end
      within ".multiselect" do
        first('.select_all').click
      end

      within ".multiselect_actions" do
        find('.edit_tags').click
      end
      fill_in 'tag_editor', :with => 'new_tag'
      find('.tag_editor').native.send_keys(:return)
      within '.main_content_list' do
        page.should have_content 'new_tag' #Waiting for tags to be posted to server
      end
      click_button "Close Window"
      within ".main_content" do
        total_workfiles = 0
        within ".content" do
          total_workfiles = all('.workfile_item').count
        end
        all('a', :text => 'new_tag').count.should == total_workfiles
      end
    end
  end
end

describe 'viewing all the entities sharing a specific tag' do
  let(:tag) { Tag.find_by_name('crazy_tag') }

  describe "when clicking a tag on a workfile" do
    let(:workfile) {workfiles(:public)}
    let(:workspace) {workfile.workspace}

    before do
      login(users(:admin))
      workfile.tag_list = ['crazy_tag']
      workfile.save!
      Sunspot.commit
    end

    it "shows a list of tagged objects scoped to a workspace that includes the tagged workfile" do
      visit("#/workspaces/#{workspace.id}/workfiles/#{workfile.id}")

      find('span', :text => 'crazy_tag').click
      current_route.should == "/workspaces/#{workspace.id}/tags/crazy_tag"

      page.should have_content("crazy_tag")

      page.should have_content(workfile.file_name)
    end
  end

  describe "when clicking a tag on a source dataset" do
    let(:dataset) { GreenplumIntegration.real_data_source.datasets.find_by_name("base_table1")}

    before do
      login(users(:admin))
      dataset.tag_list = ['crazy_tag']
      dataset.save!
      Sunspot.commit
    end

    it "shows a list of tagged objects that includes the tagged dataset" do
      visit("#/datasets/#{dataset.id}")

      find('span', :text => 'crazy_tag').click
      current_route.should == "/tags/crazy_tag"

      page.should have_content("crazy_tag")

      page.should have_content(dataset.name)
    end
  end
end
