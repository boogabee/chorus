require 'spec_helper'

describe WorkfileAccess do
  let(:context) { Object.new }
  let(:access) { WorkfileAccess.new(context)}
  let(:workfile) { workfiles(:private) }

  before do
    stub(context).current_user { user }
  end

  describe "#show?" do
    context "if the user is an admin" do
      let(:user) { users(:admin) }

      it "allows access" do
        access.can?(:show, workfile).should be_true
      end
    end

    context "if the user is a member of the workspace that the workfile is in" do
      let(:user) { users(:the_collaborator) }

      it "allows access" do
        access.can?(:show, workfile).should be_true
      end
    end

    context "if the user is not a member of the workspace that the workfile is in" do
      let(:user) { users(:default) }

      it "prevents access" do
        access.can?(:show, workfile).should be_false
      end
    end
  end

  describe "#update?" do
    context "if the user is an admin" do
      let(:user) { users(:admin) }

      it "allows access" do
        access.can?(:update, workfile).should be_true
      end
    end

    context "if the user is a member of the workspace that the workfile is in" do
      let(:user) { users(:the_collaborator) }

      it "allows access" do
        access.can?(:update, workfile).should be_true
      end
    end

    context "if the user is not a member of the workspace that the workfile is in" do
      let(:user) { users(:default) }

      it "prevents access" do
        access.can?(:update, workfile).should be_false
      end
    end
  end
end