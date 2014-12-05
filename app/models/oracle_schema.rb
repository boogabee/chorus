class OracleSchema < Schema
  attr_accessible :data_source
  alias_attribute :data_source, :parent

  has_many :data_source_account_permissions, :as => :accessed
  has_many :data_source_accounts, :through => :data_source_account_permissions

  validates :data_source, :presence => true

  def self.destroy_schemas(data_source_id)
    OracleSchema.where(:parent_id => data_source_id).destroy_all
  end

  def class_for_type(type)
    type == 't' ? OracleTable : OracleView
  end

  def self.reindex_datasets(schema_id)
    find(schema_id).datasets.not_stale.each do |dataset|
      begin
        dataset.solr_index
      rescue => e
        Chorus.log_error "Error in OracleSchema.reindex_datasets: #{e.message}"
      end
    end
    Sunspot.commit
  end
end