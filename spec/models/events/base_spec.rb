require "spec_helper"

describe Events::Base do
  describe ".add(params)" do
    it "creates an event with the given parameters" do
      gpdb_data_source1 = data_sources(:shared)
      gpdb_data_source2 = data_sources(:owners)
      user1 = users(:owner)
      user2 = FactoryGirl.create(:user)
      user3 = FactoryGirl.create(:user)
      dataset = datasets(:table)
      hdfs_entry = HdfsEntry.create({:hdfs_data_source_id => 1234, :path => "/path/file.txt"})
      workspace = workspaces(:public)

      Events::DataSourceCreated.by(user1).add(:data_source => gpdb_data_source1)
      Events::DataSourceChangedOwner.by(user2).add(:data_source => gpdb_data_source2, :new_owner => user3)
      Events::HdfsFileExtTableCreated.by(user1).add(:dataset => dataset, :hdfs_file => hdfs_entry, :workspace => workspace)

      event1 = Events::DataSourceCreated.last
      event2 = Events::DataSourceChangedOwner.last
      event3 = Events::HdfsFileExtTableCreated.last

      event1.actor.should == user1
      event1.data_source.should == gpdb_data_source1

      event2.actor.should == user2
      event2.data_source.should == gpdb_data_source2
      event2.new_owner.should == user3

      event3.workspace.should == workspace
    end
  end

  it_should_behave_like "recent"

  describe '.notification_for_current_user' do
    let(:event) { event_owner.notifications.last.event }
    let(:event_owner) { users(:owner) }

    it "retrieves the notification for the event" do
      set_current_user(event_owner)
      event.notification_for_current_user.should be_present
    end

    it "does not retrieve the notification for a user for whom there is none" do
      set_current_user(users(:no_collaborators))
      event.notification_for_current_user.should be_nil
    end
  end

  describe ".for_dashboard_of(user)" do
    let(:user) { users(:no_collaborators) }

    let(:private_event) { events(:private_workfile_created) }
    let(:public_event) { events(:public_workfile_created) }
    let(:user_creates_private_workfile_event) { events(:no_collaborators_creates_private_workfile) }

    subject { Events::Base.for_dashboard_of(user) }

    context "global events" do
      let(:workspace) { workspaces(:public) }
      let!(:workspace_activity) { Activity.create!(:entity => workspace, :event => public_event) }

      let!(:global_activity) { Activity.global.create!(:event => user_creates_private_workfile_event) }

      it "includes global events" do
        subject.should include(global_activity.event)
      end

      it "does not include multiples of the same event" do
        Activity.global.create!(:event => user_creates_private_workfile_event)

        ids = subject.map(&:id)
        ids.should == ids.uniq
      end

      it "can be filtered further (like any activerecord relation)" do
        event = global_activity.event
        subject.find(event.to_param).should == event
        subject.find_by_id(workspace_activity.event).should be_nil
      end
    end

    context "event in public workspace" do
      context "user is not a member" do
        let(:workspace) { workspaces(:public) }
        let!(:workspace_activity) { Activity.create!(:entity => workspace, :event => public_event) }

        it "does not include events" do
          subject.should_not include(workspace_activity.event)
        end
      end

      context "user is a member" do
        let(:workspace) { workspaces(:public_with_no_collaborators) }
        let!(:workspace_activity) { Activity.create!(:entity => workspace, :event => user_creates_private_workfile_event ) }

        it "includes events" do
          subject.should include(workspace_activity.event)
        end
      end
    end

    context "event in private workspace" do
      let(:workspace) { workspaces(:private) }
      let!(:workspace_activity) { Activity.create!(:entity => workspace, :event => private_event) }


      context "user is not a member" do
        it "does not include" do
          subject.should_not include(workspace_activity.event)
        end
      end

      context "user is a member" do
        it "includes events" do
          workspace.members << user
          subject.should include(workspace_activity.event)
        end
      end
    end

    context 'other events that the user has done' do
      let(:event) { Events::SchemaImportSuccess.first! }
      let(:user) { event.actor }

      it 'is included' do
        subject.should include event
      end
    end
  end

  describe "cascading deletes" do
    it "destroys all of its associated activities when it is destroyed" do
      event = Events::SourceTableCreated.last

      expect {
        event.destroy
      }.to change { Activity.where(:event_id => event.id).size }.to(0)
    end

    it "deletes its notification when it is destroyed" do
      event = Events::SourceTableCreated.last
      user = users(:owner)

      comment = Comment.create!({:body => "comment", :event_id => event.id, :author_id => user.id})
      Notification.create!({:recipient => user, :event => event, :comment => comment}, :without_protection => true)

      expect {
        event.destroy
      }.to change(event.notifications, :count).to(0)
    end

    it "deletes its comments when it is destroyed" do
      event = Events::SourceTableCreated.last
      user = users(:owner)

      Comment.create!({:body => "comment", :event_id => event.id, :author_id => user.id})

      expect {
        event.destroy
      }.to change(event.comments, :count).to(0)
    end

    it "deletes its attachments when it is destroyed" do
      event = Events::SourceTableCreated.last
      event.attachments.create!(:contents => File.new(Rails.root.join('spec', 'fixtures', 'workfile.sql')))

      expect {
        event.destroy
      }.to change(event.attachments, :count).to(0)
    end

    it "deletes its notes_workfiles when it is destroyed" do
      event = Events::SourceTableCreated.last
      event.notes_workfiles.create

      expect {
        event.destroy
      }.to change(event.notes_workfiles, :count).to(0)
    end

    it "deletes its datasets_notes when it is destroyed" do
      event = Events::SourceTableCreated.last
      event.datasets_notes.create

      expect {
        event.destroy
      }.to change(event.datasets_notes, :count).to(0)
    end

    it "deletes its notes_workflow_results when it is destroyed" do
      event = Events::SourceTableCreated.last
      event.notes_work_flow_results.create

      expect {
        event.destroy
      }.to change(event.notes_work_flow_results, :count).to(0)
    end
  end

  describe "with deleted" do
    before do
      any_instance_of(GreenplumConnection) do |data_source|
        stub(data_source).running? { false }
      end
    end

    describe "workspace" do
      it "still has access to the workspace" do
        workspace = Workspace.last
        event = Events::Base.create!({:workspace => workspace}, :as => :create)
        workspace.destroy
        event.reload.workspace.should == workspace
      end
    end

    describe "actor" do
      it "still has access to the actor" do
        actor = users(:not_a_member)
        event = Events::Base.create!({:actor => actor}, :as => :create)
        actor.destroy
        event.reload.actor.should == actor
      end
    end

    describe "targets" do
      it "still has access to the targets" do
        event = Events::Base.where("target1_id IS NOT NULL AND target2_id IS NOT NULL").last
        target1 = event.target1
        target2 = event.target2
        target1.destroy
        target2.destroy
        event.reload
        event.target1.should == target1
        event.target2.should == target2
      end
    end

    describe "promoted_by" do
      let(:promoter) { users(:not_a_member) }
      let(:event) { Events::Base.create!({:actor => promoter}, :as => :create) }

      before do
        event.promoted_by = promoter
        event.save!
        event.reload
      end

      it "still has access to the promoter" do
        event.promoted_by.should == promoter
        promoter.destroy
        event.reload
        event.promoted_by.should == promoter
      end
    end
  end

  describe ".visible_to(user)" do
    let(:user) { users(:no_collaborators) }

    let(:private_event) { events(:private_workfile_created) }
    let(:public_event) { events(:public_workfile_created) }
    let(:user_creates_private_workfile_event) { events(:no_collaborators_creates_private_workfile) }

    subject { Events::Base.visible_to(user) }

    context "global events" do
      let(:workspace) { workspaces(:private) }
      let!(:workspace_activity) { Activity.create!(:entity => workspace, :event => private_event) }

      let!(:global_activity) { Activity.global.create!(:event => user_creates_private_workfile_event) }

      it "includes global events" do
        subject.should include(global_activity.event)
      end

      it "does not include multiples of the same event" do
        Activity.global.create!(:event => user_creates_private_workfile_event)

        ids = subject.map(&:id)
        ids.should == ids.uniq
      end

      it "can be filtered further (like any activerecord relation)" do
        event = global_activity.event
        subject.find(event.to_param).should == event
        subject.find_by_id(workspace_activity.event).should be_nil
      end
    end

    context "event on public workspace" do
      context "user is not a member" do
        let(:workspace) { workspaces(:public) }
        let!(:workspace_activity) { Activity.create!(:entity => workspace, :event => public_event) }

        it "does include events" do
          subject.should include(workspace_activity.event)
        end
      end

      context "user is a member" do
        let(:workspace) { workspaces(:public_with_no_collaborators) }
        let!(:workspace_activity) { Activity.create!(:entity => workspace, :event => user_creates_private_workfile_event ) }

        it "includes events" do
          subject.should include(workspace_activity.event)
        end
      end
    end

    context "when the event is in a private workspace" do
      let(:workspace) { workspaces(:private) }
      let!(:workspace_activity) { Activity.create!(:entity => workspace, :event => private_event) }


      context "user is not a member" do
        it "does not include" do
          subject.should_not include(workspace_activity.event)
        end

        context "when the user is an admin" do
          let(:user) { users(:admin) }

          it "should include the event" do
            subject.should include(workspace_activity.event)
          end
        end
      end

      context "user is a member" do
        it "includes events" do
          workspace.members << user
          subject.should include(workspace_activity.event)
        end
      end
    end
  end

  it_behaves_like 'a soft deletable model' do
    let(:model) { events(:public_workfile_created) }
  end
end
