class DataSourceAccountAccess < DefaultAccess
  def update?(account)
    current_user.admin? || account.owner == current_user
  end
end