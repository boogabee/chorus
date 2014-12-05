class OracleViewAccess < AdminFullAccess
  def show?(view)
    OracleDataSourceAccess.new(context).can? :show, view.data_source
  end
end