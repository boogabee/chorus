class Dataset < ActiveRecord::Base
  include Stale
  include SoftDelete
  include TaggableBehavior
  include Notable

  unscoped_belongs_to :schema

  validates_presence_of :scoped_schema, :if => :needs_schema?
  validates_presence_of :name

  has_many :activities, :as => :entity
  has_many :events, :through => :activities
  has_many :comments, :through => :events
  has_many :most_recent_comments, :through => :events, :source => :comments, :class_name => "Comment", :order => "id DESC", :limit => 1
  has_many :associated_datasets, :dependent => :destroy
  has_many :bound_workspaces, :through => :associated_datasets, :source => :workspace
  has_many :imports, :as => :source
  has_many :tableau_workbook_publications, :dependent => :destroy

  searchable_model :if => :should_reindex? do
    text :name, :stored => true, :boost => SOLR_PRIMARY_FIELD_BOOST
    text :database_name, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
    text :table_description, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
    text :schema_name, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
    text :column_name, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
    text :column_description, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
    text :query, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
  end

  has_shared_search_fields [
                               {:type => :integer, :name => :data_source_account_ids, :options => {:multiple => true}},
                               {:type => :integer, :name => :found_in_workspace_id, :options => {:multiple => true}}
                           ]

  after_destroy :cancel_imports

  attr_accessor :highlighted_attributes, :search_result_notes, :skip_search_index
  attr_accessible :name

  delegate :data_source, :accessible_to, :connect_with, :connect_as, :to => :schema

  def needs_schema?
    true
  end

  def self.eager_load_associations
    [
      :tags,
      {:scoped_schema => :scoped_parent},
      {:bound_workspaces => :tags},
      :tableau_workbook_publications,
      :most_recent_notes,
      :most_recent_comments
    ]
  end

  def self.eager_load_succinct_associations
    [
        {:scoped_schema => :scoped_parent}
    ]
  end

  def self.add_search_permissions(current_user, search)
    search.build do
      any_of do
        # Restrict all documents that inherit from RelationalDataset
        # such that they must match data_source_account_ids visible to the current user
        without :security_type_name, RelationalDataset.name
        account_ids = current_user.accessible_account_ids
        with :data_source_account_ids, account_ids unless account_ids.blank?
      end

      any_of do
        without :security_type_name, ChorusView.name
        with :member_ids, current_user.id
        with :public, true
      end

      any_of do
        without :security_type_name, HdfsDataset.name
        with :member_ids, current_user.id
        with :public, true
      end
    end
  end

  def self.with_name_like(name)
    if name.present?
      like_string = "%#{DataSourceConnection.escape_like_string(name)}%"
      where("datasets.name ILIKE ? ESCAPE '#{DataSourceConnection::LIKE_ESCAPE_CHARACTER}'", like_string)
    else
      scoped
    end
  end

  def self.list_order
    order("lower(replace(datasets.name,'_','')), id")
  end

  def self.tables
    where("datasets.type LIKE '%Table'")
  end

  def self.views
    views_tables.where("datasets.type LIKE '%View'")
  end

  def self.views_tables
    where("datasets.type <> 'ChorusView'")
  end

  def self.chorus_views
    where(:type => 'ChorusView')
  end

  def self.filter_by_name(datasets, name)
    if name.present?
      datasets.select do |dataset|
        dataset.name =~ /#{name}/i
      end
    else
      datasets
    end
  end

  def should_reindex?
    !stale? && !skip_search_index
  end

  def self.find_and_verify_in_source(dataset_id, user)
    dataset = find(dataset_id)
    unless dataset.verify_in_source(user)
      raise ActiveRecord::RecordNotFound
    end
    dataset
  end

  def self.refresh(account, schema, options = {})
    schema.refresh_datasets account, options
  end

  def query_setup_sql
    ""
  end

  def all_rows_sql(limit = nil)
    Arel::Table.new(name).project('*').take(limit).to_sql
  end

  def preview_sql
    all_rows_sql
  end

  def as_sequel
    Sequel.qualify(schema.name, name)
  end

  def entity_type_name
    'dataset'
  end

  def type_name
    'Dataset'
  end

  def schema_name
    schema.name
  end

  def column_name
    column_data.map(&:name)
  end

  def column_description
    column_data.map(&:description).compact
  end

  def column_data
    cache(:column_data) do
      DatasetColumn.columns_for(schema.data_source.owner_account, self)
    end
  end

  def table_description
    cache(:table_description) do
      DatasetStatistics.build_for(self, schema.data_source.owner_account).description
    end
  rescue
    nil
  end

  def cache(key, &block)
    cache_key = {:model_class => self.class.name, :model_id => id, :key => key}
    Rails.cache.fetch(cache_key, :expires_in => 1.minutes, &block)
  end

  def associable?
    raise NotImplementedError
  end

  def in_workspace?(workspace)
    raise NotImplementedError
  end

  def execution_location
    raise NotImplementedError
  end

  private

  def cancel_imports
    imports.unfinished.each do |import|
      import.cancel(false, "Source/Destination of this import was deleted")
    end
  end
end