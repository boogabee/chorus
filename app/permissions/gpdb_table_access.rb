class GpdbTableAccess < AdminFullAccess
  def show?(gpdb_table)
    GpdbDataSourceAccess.new(context).can? :show, gpdb_table.data_source
  end
end
