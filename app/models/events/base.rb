require 'json_hash_serializer'

module Events
  class Base < ActiveRecord::Base
    include SoftDelete
    include Recent

    def self.activity_stream_eager_load_associations
      [
          {:attachments => :note},
          {:workfiles => {:latest_workfile_version => :workfile}},
          {:comments => :author},
          :datasets,
          :actor,
          :promoted_by,
          :target1,
          :target2,
          :workspace
      ]
    end

    self.table_name = :events
    self.inheritance_column = :action
    serialize :additional_data, JsonHashSerializer

    class_attribute :entities_that_get_activities, :target_names, :object_translations
    attr_accessible :actor, :action, :target1, :target2, :target3, :workspace, :additional_data, :as => :create

    has_many :activities, :foreign_key => :event_id, :dependent => :destroy
    has_many :notifications, :foreign_key => :event_id, :dependent => :destroy
    has_one :notification_for_current_user, :class_name => 'Notification', :conditions => proc {
      "recipient_id = #{current_user.id}"
    }, :foreign_key => :event_id

    has_many :comments, :foreign_key => :event_id, :dependent => :destroy

    # subclass associations on parent to facilitate .includes
    has_many :attachments, :class_name => 'Attachment', :foreign_key => 'note_id', :dependent => :destroy
    has_many :notes_workfiles, :foreign_key => 'note_id', :dependent => :destroy
    has_many :workfiles, :through => :notes_workfiles
    has_many :notes_work_flow_results, :foreign_key => 'note_id', :dependent => :destroy
    has_many :datasets_notes, :foreign_key => 'note_id', :dependent => :destroy
    has_many :datasets, :through => :datasets_notes

    belongs_to :actor, :class_name => 'User'
    belongs_to :target1, :polymorphic => true
    belongs_to :target2, :polymorphic => true
    belongs_to :target3, :polymorphic => true
    belongs_to :workspace
    belongs_to :promoted_by, :class_name => 'User'

    [:actor, :workspace, :target1, :target2, :target3, :promoted_by].each do |method|
      define_method("#{method}_with_deleted") do
        original_method = :"#{method}_without_deleted"
        send(original_method) || try_unscoped(method) { send(original_method, true) }
      end
      alias_method_chain method, :deleted
    end

    def self.by(actor)
      where(:actor_id => actor.id)
    end

    def self.add(params)
      event = new(params, :as => :create)
      event.build_activities
      event.save!
      event
    end

    def self.presenter_class
      EventPresenter
    end

    def action
      self.class.name.demodulize
    end

    def targets
      self.class.target_names.reduce({}) do |hash, target_name|
        hash[target_name] = send(target_name)
        hash
      end
    end

    def self.for_dashboard_of(user)
      workspace_activities = <<-SQL
      activities.entity_id IN (
        SELECT workspace_id
        FROM memberships
        WHERE user_id = #{user.id})
      SQL
      self.activity_query(user, workspace_activities)
    end

    def self.visible_to(user)
      workspace_activities = <<-SQL
      activities.entity_id IN (
        SELECT workspace_id
        FROM memberships
        WHERE user_id = #{user.id})
      OR workspaces.public = true
      OR (SELECT admin FROM users WHERE id = #{user.id}) = true
      SQL
      self.activity_query(user, workspace_activities).joins('LEFT OUTER JOIN "workspaces" ON "workspaces"."id" = "events"."workspace_id"')
    end

    def build_activities
      self.class.entities_that_get_activities.try(:each) do |entity_name|
        build_activity(entity_name)
      end
    end

    private

    def self.activity_query(user, workspace_activities)
      group("events.id").readonly(false).
          joins(:activities).
          where(%Q{(events.published = true) OR (events.actor_id=#{user.id}) OR (activities.entity_type = 'GLOBAL') OR (activities.entity_type = 'Workspace'
          AND (#{workspace_activities}))})
    end

    def build_activity(entity_name)
      if entity_name == :global
        activities.build(:entity_type => Activity::GLOBAL)
      else
        entity = send(entity_name)
        activities.build(:entity => entity)
      end
    end

    def self.has_targets(*target_names)
      options = target_names.extract_options!
      self.target_names = target_names
      self.attr_accessible(*target_names, :as => [:create])

      target_names.each_with_index do |name, i|
        alias_getter_and_setter("target#{i+1}", name, options)
      end

      alias_method("primary_target", target_names.first)
    end

    def self.alias_getter_and_setter(existing_name, new_name, options)
      # The events table has a dedicated 'workspace_id' column,
      # so we don't alias :workspace to :target1 or :target2.
      # Subclasses should still specify the workspace as
      # a target if they need the workspace to be included
      # in their JSON representation.
      return if new_name == :workspace

      alias_method("#{new_name}=", "#{existing_name}=")
      alias_method(new_name, existing_name)
    end

    def self.has_activities(*entity_names)
      self.entities_that_get_activities = entity_names
    end

    private

    def try_unscoped(method, &block)
      target_class(method).try(:unscoped, &block)
    end

    def target_class(method)
      case method
        when :actor, :promoted_by then User
        when :workspace then Workspace
        else
          type = try(:"#{method}_type")
          type.constantize if type
      end
    end
  end
end
