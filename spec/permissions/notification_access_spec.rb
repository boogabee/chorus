require "spec_helper"

describe NotificationAccess do
  let(:fake_controller) { ApplicationController.new }
  let(:access) { NotificationAccess.new(fake_controller) }
  let(:notification) { notifications(:notification1) }

  describe "#destroy?" do
    context " when the current user is the notification's recipient" do
      it "returns true" do
        stub(fake_controller).current_user { notification.recipient }
        access.destroy?(notification).should be_true
      end
    end

    context "when the current user is not the recipient" do
      it "returns true" do
        stub(fake_controller).current_user { users(:no_collaborators) }
        access.destroy?(notification).should be_false
      end
    end
  end
end
