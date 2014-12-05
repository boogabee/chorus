class WorkspaceMembersManager

  def initialize(workspace, member_ids, acting_user)
    @workspace = workspace
    @member_ids = member_ids
    @acting_user = acting_user
  end

  def update_membership
    workspace_current_members = @workspace.members.map(&:id)
    new_members = @member_ids.map(&:to_i) - workspace_current_members
    removed_member_ids = workspace_current_members - @member_ids.map(&:to_i)

    @workspace.transaction do
      @workspace.update_attributes!(:member_ids => @member_ids, :has_added_member => true)
      transfer_job_ownership(removed_member_ids)
    end

    create_events(new_members)
    @workspace.solr_reindex_later
  end

  private

  def transfer_job_ownership(removed_member_ids)
    Job.where(:workspace_id => @workspace.id, :owner_id => removed_member_ids).each(&:reset_ownership!)
  end

  def create_events(new_members)
    unless new_members.empty?
      member = User.find(new_members.first)
      num_added = new_members.count
      member_added_event = Events::MembersAdded.by(@acting_user).add(:workspace => @workspace, :member => member, :num_added => num_added)
      new_members.each do |new_member_id|
        Notification.create!(:recipient_id => new_member_id.to_i, :event_id => member_added_event.id)
      end
    end
  end
end
