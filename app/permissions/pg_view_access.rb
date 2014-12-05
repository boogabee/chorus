class PgViewAccess < AdminFullAccess
  def show?(view)
    PgDataSourceAccess.new(context).can? :show, view.data_source
  end
end
