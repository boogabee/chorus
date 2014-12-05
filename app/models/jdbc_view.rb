class JdbcView < JdbcDataset
  def verify_in_source(user)
    schema.verify_in_source(user) && schema.connect_as(user).view_exists?(name)
  end
end
