module EventHelpers
  def it_creates_activities_for(&entities_block)
    it "creates the right entity-specific activities" do
      subject.save!
      expected_entities = instance_exec(&entities_block)
      activities = Activity.where(:event_id => subject.id)
      activities.map(&:entity).compact.should =~ expected_entities
    end
  end

  def it_creates_a_global_activity
    it "creates a global activity" do
      subject.save!
      global_activity = Activity.global.find_by_event_id(subject.id)
      global_activity.should_not be_nil
    end
  end

  def it_does_not_create_a_global_activity
    it "does not create a global activity" do
      subject.save!
      global_activity = Activity.global.find_by_event_id(subject.id)
      global_activity.should be_nil
    end
  end

end

shared_examples 'event associated with a workspace' do
  let(:workspace) { workspaces(:private_with_no_collaborators) }
  let(:not_a_member)      { users(:not_a_member) }
  let(:member)            { users(:no_collaborators) }

  it "is associated with the workspace" do
    subject.save!
    workspace.events.should include(subject)
  end
end
