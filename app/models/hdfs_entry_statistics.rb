class HdfsEntryStatistics
  attr_reader :owner, :group, :modified_at, :accessed_at,
              :file_size, :block_size, :permissions, :replication

  def initialize(stats)
    @owner = stats.owner
    @group = stats.group
    @modified_at = stats.modified_at
    @accessed_at = stats.accessed_at
    @file_size = stats.size
    @block_size = stats.block_size
    @permissions = stats.permissions
    @replication = stats.replication
  end

  def entity_type_name
    'hdfs_entry_statistics'
  end
end
