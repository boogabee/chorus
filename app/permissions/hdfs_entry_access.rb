class HdfsEntryAccess < AdminFullAccess
  def show?(hdfs_entry)
    HdfsDataSourceAccess.new(context).can? :show, hdfs_entry.hdfs_data_source
  end
end