require 'events/base'
require 'model_map'

module Events
  class Note < Base
    include SearchableHtml

    validates_presence_of :actor_id
    validate :no_note_on_archived_workspace, :on => :create
    validates_presence_of :workspace, :if => :has_workspace?

    searchable_html :body
    searchable_model

    attr_accessible :note_target, :workspace_id, :is_insight, :insight, :as => :create
    attr_accessible :dataset_ids, :workfile_ids, :as => [:create, :default]

    has_additional_data :body

    delegate :grouping_id, :type_name, :security_type_name, :to => :primary_target

    before_validation :set_promoted_info, :if => lambda { insight && insight_changed? }
    before_validation :set_actor_to_current_user, :if => lambda { current_user && !actor }

    before_create :build_activities

    alias_attribute :is_insight, :insight

    def self.build_for(model, params)
      params[:note_target] = model

      model_class = case model
                      when Workfile then
                        Workfile
                      when HdfsEntry then
                        HdfsFile
                      when Dataset
                        params[:workspace_id] ? 'WorkspaceDataset' : Dataset
                      when DataSource
                        DataSource
                      else
                        model.class
                    end
      note = Events.const_get("NoteOn#{model_class}").new(params, :as => :create)

      build_work_flow_results(note, params)

      note
    end

    def self.build_work_flow_results(note, params)
      if params[:result_id]
        note.notes_work_flow_results.build(:result_id => params[:result_id])
      end
    end

    def self.insights
      where(:insight => true)
    end

    def promote_to_insight
      self.insight = true
      save!
    end

    def demote_from_insight
      self.insight = false
      save!
    end

    def set_insight_published(published)
      self.published = published
      save!
    end

    def note_target=(model)
      self.target1 = model
    end

    def note_target
      self.target1
    end

    def demotable_by(user)
      return true if user.admin?
      return true if user == promoted_by
      return true if workspace && user == workspace.owner
      return false
    end

    private

    def has_workspace?
      false
    end

    def no_note_on_archived_workspace
      errors.add(:workspace, :archived) if workspace.present? && workspace.archived?
    end

    def set_promoted_info
      self.promoted_by = current_user
      self.promotion_time = Time.current
      true
    end

    def set_actor_to_current_user
      self.actor = current_user
    end

    class << self
      private

      def include_shared_search_fields(target_name)
        klass = ModelMap.class_from_type(target_name.to_s)
        define_shared_search_fields(klass.shared_search_fields, target_name)
      end
    end
  end
end
