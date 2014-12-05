require 'spec_helper'

shared_examples 'a job finished event' do |condition, notify_attribute|
  context "when notify is set to 'everybody'" do
    before do
      job.update_attribute(notify_attribute, 'everybody')
    end

    it "on creation, notifies all members of its workspace" do
      expect {
        expect {
          expect {
            event
          }.to change(member.notifications, :count).by(1)
        }.to change(no_emails_member.notifications, :count).by(1)
      }.not_to change(non_member.notifications, :count)

      member.notifications.last.event.should == event
    end

    it "emails those it notifies" do
      event
      ActionMailer::Base.deliveries.map(&:to).reduce(&:+).should =~ workspace.members.where(:subscribed_to_emails => true).map(&:email)
    end
  end

  context "when notify is set to 'selected'" do
    before do
      job.update_attribute(notify_attribute, 'selected')
      job.notify_on(condition, member)
    end

    it "on creation, notifies selected members of its workspace" do
      expect {
        expect{
          expect {
            event
          }.to change(member.notifications, :count).by(1)
        }.not_to change(no_emails_member.notifications, :count).by(1)
      }.not_to change(non_member.notifications, :count)

      member.notifications.last.event.should == event
    end
  end

  context "when notify is set to 'nobody'" do
    before do
      job.send(notify_attribute).should == 'nobody'
    end

    it "on creation, notifies no one" do
      expect {
        event
      }.not_to change(Notification, :count)
    end
  end
end
