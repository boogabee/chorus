class JdbcSchema < Schema
  attr_accessible :data_source
  alias_attribute :data_source, :parent

  has_many :data_source_account_permissions, :as => :accessed
  has_many :data_source_accounts, :through => :data_source_account_permissions

  validates :data_source, :presence => true

  def self.destroy_schemas(data_source_id)
    JdbcSchema.where(:parent_id => data_source_id).destroy_all
  end

  def class_for_type(type)
    type == 't' ? JdbcTable : JdbcView
  end
end