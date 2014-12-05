class PgSchema < Schema
  include SandboxSchema

  has_many :views, :source => :datasets, :class_name => 'PgView', :foreign_key => :schema_id

  def class_for_type(type)
    type == 'r' ? PgTable : PgView
  end
end
