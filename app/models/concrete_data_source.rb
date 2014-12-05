class ConcreteDataSource < DataSource
  validates_presence_of :db_name
  validates_numericality_of :port, :only_integer => true
end