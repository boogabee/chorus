class JdbcTableAccess < AdminFullAccess
  def show?(table)
    JdbcDataSourceAccess.new(context).can? :show, table.data_source
  end
end
