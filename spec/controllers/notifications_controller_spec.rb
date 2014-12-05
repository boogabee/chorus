require "spec_helper"

describe NotificationsController do
  let(:notification1) { notifications(:notification1) }
  let(:notification2) { notifications(:notification2) }
  let(:event1) { notification1.event }
  let(:event2) { notification2.event }
  let(:current_user) { users(:owner) }

  before do
    log_in current_user
  end

  describe "#index" do
    it "is successful" do
      get :index
      response.code.should == "200"
    end

    it "shows list of notifications" do
      get :index
      notifications = decoded_response
      matching_notification = notifications.find { |n| n.id == notification1.id }

      event = matching_notification.event
      event.actor.id.should == event1.actor_id
      event.data_source.id.should == event1.target1_id
      event.body.should == event1.body
      matching_notification.should have_key(:unread)
    end

    it "should paginate notifications" do
      get :index, :per_page => 1
      decoded_response.length.should == 1
    end

    it "passes the succinct option to the Presenter" do
      mock_present do |models, view, options|
        options[:succinct].should be_true
        options[:activity_stream].should be_true
      end
      get :index
    end

    context "when the unread parameter is passed" do
      it "only returns unread notifications" do
        put :read, :notification_ids => [notification1.id]
        get :index, :type => 'unread'
        decoded_response.length.should == current_user.notifications.length - 1
      end
    end

    generate_fixture "notificationSet.json" do
      put :read, :notification_ids => [notification1.id]
      get :index
    end

    it "generates a fixture for a single notification", :fixture do
      put :read, :notification_ids => [notification1.id]
      get :index
      save_fixture "notification.json", { :response => response.decoded_body["response"].first }
    end
  end

  describe '#read' do
    it "marks all notifications passed as read" do
      notification1.read.should be_false
      put :read, :notification_ids => [notification1.id]
      notification1.reload.read.should be_true
      response.code.should == '200'
    end
  end

  describe "#destroy" do
    let(:note) {events(:note_on_greenplum)}
    before(:each) do
      @notification = Notification.create!({:recipient => current_user, :event => note}, :without_protection => true)
    end

    it "uses authorization" do
      mock(subject).authorize! :destroy, @notification
      delete :destroy, :id => @notification.id
    end

    describe "deleting" do
      before do
        delete :destroy, :id => @notification.id
      end

      it "should soft delete the notification" do
        notification = Notification.find_with_destroyed(@notification.id)
        notification.deleted_at.should_not be_nil
      end

      it "should respond with success" do
        response.should be_success
      end
    end
  end
end
