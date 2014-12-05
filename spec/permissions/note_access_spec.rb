require "spec_helper"

describe Events::NoteAccess do
  let(:fake_controller) { ApplicationController.new }
  let(:access) { Events::NoteAccess.new(fake_controller) }
  let(:note) { events(:note_on_greenplum) }

  describe "#show?" do
    context " when the current user is the note's actor" do
      it "returns true" do
        stub(fake_controller).current_user { users(:owner) }
        access.show?(note).should be_true
      end
    end

    context "when the current user is an admin" do
      it "returns true" do
        admin = users(:admin)
        stub(fake_controller).current_user { admin }
        access.show?(note).should be_true
      end
    end

    context "when the note is on a workspace and the current user is the workspace owner" do
      let!(:note) do
        with_current_user(users(:no_collaborators)) do
          Events::NoteOnWorkspace.create!({
              :note_target => workspaces(:public),
              :body => "hi"
          }, :as => :create)
        end
      end

      it "returns true" do
        stub(fake_controller).current_user { note.workspace.owner }
        access.show?(note).should be_true
      end
    end

    context "when the note is on a model not visible to the user" do
      let!(:note) do
        with_current_user(users(:owner)) do
          Events::NoteOnWorkspace.create!({
              :note_target => workspaces(:private),
              :body => "You can't see me"
          }, :as => :create)
        end
      end

      it "fails" do
        other_user = FactoryGirl.build(:user)
        stub(fake_controller).current_user { other_user }

        access.show?(note).should be_false
      end
    end
  end


  describe "#destroy?" do
    context " when the current user is the note's actor" do
      it "returns true" do
        stub(fake_controller).current_user { users(:owner) }
        access.destroy?(note).should be_true
      end
    end

    context "when the current user is an admin" do
      it "returns true" do
        admin = users(:admin)
        stub(fake_controller).current_user { admin }
        access.destroy?(note).should be_true
      end
    end

    context "when the note is on a workspace and the current user is the workspace owner" do
      let(:note) do
        with_current_user(users(:no_collaborators)) do
          Events::NoteOnWorkspace.create!({
              :note_target => workspaces(:public),
              :body => "hi"
          }, :as => :create)
        end
      end

      it "returns true" do
        stub(fake_controller).current_user { note.workspace.owner }
        access.destroy?(note).should be_true
      end
    end

    it "returns false otherwise" do
      other_user = FactoryGirl.build(:user)
      stub(fake_controller).current_user { other_user }
      access.destroy?(note).should be_false
    end
  end

  describe "#update?" do
    context " when the current user is the note's actor" do
      it "returns true" do
        stub(fake_controller).current_user { users(:owner) }
        access.update?(note).should be_true
      end
    end

    it "returns false otherwise" do
      other_user = FactoryGirl.build(:user)
      stub(fake_controller).current_user { other_user }
      access.update?(note).should be_false
    end
  end

  describe "classes for individual note types" do
    it "has a class for each type of note" do
      Events::NoteOnWorkspaceAccess.new(fake_controller).should be_a Events::NoteAccess
      Events::NoteOnDataSourceAccess.new(fake_controller).should be_a Events::NoteAccess
      Events::NoteOnHdfsDataSourceAccess.new(fake_controller).should be_a Events::NoteAccess
    end
  end
end
