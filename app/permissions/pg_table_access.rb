class PgTableAccess < AdminFullAccess
  def show?(table)
    PgDataSourceAccess.new(context).can? :show, table.data_source
  end
end
