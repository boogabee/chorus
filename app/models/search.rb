class Search
  include ActiveModel::Validations
  include ChorusApiValidationFormat
  attr_accessor :query, :page, :per_page, :workspace_id, :search_type, :tag_param, :tag, :entity_type
  attr_reader :current_user
  attr_writer :per_type

  validate :valid_entity_type

  AVAILABLE_MODELS = [
      User,
      GpdbDataSource,
      HdfsDataSource,
      GnipDataSource,
      Workspace,
      Workfile,
      Dataset,
      HdfsEntry,
      Attachment,
      OracleDataSource,
      JdbcDataSource,
      PgDataSource
  ]

  def initialize(current_user, params = {})
    @current_user = current_user
    self.query = params[:query]
    self.per_type = params[:per_type]
    self.workspace_id = params[:workspace_id]
    self.search_type = params[:search_type]
    self.tag_param = params[:tag].to_s == 'true'
    self.tag = Tag.find_by_name(query) if is_tag_search?
    if per_type > 0
      self.per_page = 100
    else
      self.page = params[:page] || 1
      self.per_page = params[:per_page] || 50
    end
    self.entity_type = params[:entity_type]
  end

  def is_tag_search?
    !!tag_param
  end

  def models_to_search
    AVAILABLE_MODELS.select do |model|
      entity_type.nil? || class_name_to_key(model.type_name) == class_name_to_key(entity_type)
    end
  end

  def models_with_tags
    models_to_search.select { |m| m.taggable? }
  end

  def search
    @search ||= begin
      raise ApiValidationError.new(errors) unless valid?
      return if tag_missing?

      begin
        search = build_search
        search.execute
        search
      rescue => e
        raise SunspotError.new(e.message)
      end
    end
  end

  def models
    @models ||= begin
      models = Hash.new() { |hsh, key| hsh[key] = [] }

      return models if tag_missing? || query_empty?

      search.associate_grouped_notes_with_primary_records

      search.results.each do |result|
        model_key = class_name_to_key(result.type_name)
        models[model_key] << result unless per_type > 0 && models[model_key].length >= per_type
      end

      populate_missing_records models

      models[:this_workspace] = workspace_specific_results.results if workspace_specific_results
      models
    end
  end

  def users
    models[:users]
  end

  def data_sources
    models[:data_sources]
  end

  def workspaces
    models[:workspaces]
  end

  def workfiles
    models[:workfiles]
  end

  def datasets
    models[:datasets]
  end

  def hdfs_entries
    models[:hdfs_entries]
  end

  def attachments
    models[:attachments]
  end

  def this_workspace
    models[:this_workspace]
  end

  def num_found
    @num_found ||= begin
      found_so_far = Hash.new(0)

      return found_so_far if (tag_missing? || query_empty?)

      if count_using_facets?
        search.facet(:type_name).rows.each do |facet|
          found_so_far[class_name_to_key(facet.value)] = facet.count
        end
      else
        found_so_far[class_name_to_key(models_to_search.first.type_name)] = search.group(:grouping_id).total
      end

      found_so_far[:this_workspace] = workspace_specific_results.num_found if workspace_specific_results
      found_so_far
    end
  end

  def per_type
    @per_type.to_i
  end

  def workspace
    @_workspace ||= Workspace.find(workspace_id)
  end

  private

  def query_empty?
    query.blank? || query =~ /^[\+\-]$/
  end

  def tag_missing?
    is_tag_search? && tag.nil?
  end
  
  def count_using_facets?
    type_names_to_search.length > 1
  end

  def class_name_to_key(name)
    name.to_s.underscore.pluralize.to_sym
  end

  def populate_missing_records(models)
    type_names_to_search.each do |type_name|
      model_key = class_name_to_key(type_name)
      found_count = models[model_key].length
      if found_count < per_type && found_count < num_found[model_key]
        model_search = Search.new(current_user, :query => query, :per_page => per_type, :entity_type => type_name)
        models[model_key] = model_search.models[model_key]
      end
    end
  end

  def type_names_to_search
    models_to_search.map(&:type_name).uniq
  end

  def workspace_specific_results
    return unless workspace_id.present?
    @workspace_specific_results ||= begin
      options = {:workspace_id => workspace_id, :query => query, :tag => is_tag_search?}
      options.merge!(:entity_type => entity_type) if entity_type
      options.merge!(:per_page => per_type) if per_type > 0
      WorkspaceSearch.new(current_user, options)
    end
  end

  def valid_entity_type
    errors.add(:entity_type, :invalid_entity_type) if models_to_search.blank?
  end

  private

  def build_search
    search = Sunspot.new_search(*(models_to_search + [Events::Note, Comment])) do
      group :grouping_id do
        limit 3
        truncate
      end

      if is_tag_search?
        with :tag_ids, tag.id
        order_by :sort_name
      else
        fulltext query do
          highlight :max_snippets => 100
        end
      end

      paginate :page => page, :per_page => per_page

      if count_using_facets?
        facet :type_name
      end

      with :type_name, type_names_to_search

      adjust_solr_params do |params|
        if params[:qf]
          fields = params[:qf].split
          new_fields = fields.map {|field| field.sub /_texts$/, "_stemmed_texts" }
          params[:qf] = (fields + new_fields).join(" ")
        end
      end
    end

    models_to_search.each do |model_to_search|
      model_to_search.add_search_permissions(current_user, search) if model_to_search.respond_to? :add_search_permissions
    end
    search
  end
end
