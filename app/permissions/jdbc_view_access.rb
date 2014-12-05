class JdbcViewAccess < AdminFullAccess
  def show?(view)
    JdbcDataSourceAccess.new(context).can? :show, view.data_source
  end
end
