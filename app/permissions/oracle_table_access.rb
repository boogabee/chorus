class OracleTableAccess < AdminFullAccess
  def show?(table)
    OracleDataSourceAccess.new(context).can? :show, table.data_source
  end
end