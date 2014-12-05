require File.join(File.dirname(__FILE__), 'spec_helper')

describe "alpine workfiles" do
  pending do
    let(:workspace) { workspaces(:public) }
    let(:user) { workspace.owner }
    let(:workfile) { workfiles('alpine_flow') }

    subject { page }

    before do
      login user
    end

    describe "the show page" do
      before do
        visit("#/workspaces/#{workspace.id}/workfiles/#{workfile.id}")
      end

      context "when the user is a member" do
        it "shows the open file button" do
          page.find(".action_bar_highlighted").should have_content("Open File")
        end
      end

      context "when the user is not a workspace member" do
        let(:user) { users(:no_collaborators) }

        it "does not show the open file button" do
          page.find(".action_bar_highlighted").should_not have_content("Open File")
        end
      end

      context "when the workspace is archived" do
        before do
          workspace.archived='true'
          workspace.archiver=users(:admin)
          workspace.save!
        end

        it "does not show the open file button" do
          workspace.reload.archived?.should be_true
          page.find(".action_bar_highlighted").should_not have_content("Open File")
        end
      end
    end
  end
end