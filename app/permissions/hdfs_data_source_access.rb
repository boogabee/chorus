class HdfsDataSourceAccess < AdminFullAccess
  def edit?(hdfs_data_source)
    hdfs_data_source.owner == current_user
  end

  def show?(_)
    true
  end

  def show_contents?(_)
    true
  end
end
