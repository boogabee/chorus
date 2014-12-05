require "spec_helper"

describe UserAccess do
  describe "#update?" do
    let(:other_user) { users(:the_collaborator) }
    let(:user_access) do
      controller = Object.new
      stub(controller).current_user { user }
      UserAccess.new(controller)
    end

    context "user is admin" do
      let(:user) { users(:admin) }

      it "allows updating of the user" do
        user_access.can?(:update, other_user).should be_true
      end
    end

    context "user is not admin" do
      let(:user) { users(:owner) }

      context "user is updating themselves" do
        it "should be allowed" do
          user_access.can?(:update, user).should be_true
        end
      end

      context "user is updating someone else" do
        it "should not be allowed" do
          user_access.can?(:update, other_user).should be_false
        end
      end

      it "can show any user" do
        user_access.can?(:show, other_user).should be_true
      end
    end
  end
end
