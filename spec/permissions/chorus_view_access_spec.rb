require 'spec_helper'

describe ChorusViewAccess do
  let(:context) { Object.new }
  let(:access) { ChorusViewAccess.new(context)}
  let(:chorus_view) { datasets(:private_chorus_view) }

  before do
    stub(context).current_user { user }
  end

  describe "#show?" do
    context "if the user is an admin" do
      let(:user) { users(:admin) }

      it "allows access" do
        access.can?(:show, chorus_view).should be_true
      end
    end

    context "if the user is a member of the workspace that the chorus_view is in" do
      let(:user) { users(:the_collaborator) }

      it "allows access" do
        access.can?(:show, chorus_view).should be_true
      end
    end

    context "if the user is not a member of the workspace that the chorus_view is in" do
      let(:user) { users(:default) }

      it "prevents access" do
        access.can?(:show, chorus_view).should be_false
      end
    end
  end
end