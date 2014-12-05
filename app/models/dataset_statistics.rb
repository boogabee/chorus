class DatasetStatistics
  attr_reader :description, :definition, :row_count, :column_count, :table_type,
              :last_analyzed, :disk_size, :partition_count

  def initialize(row)
    row = row.with_indifferent_access

    @definition   = row['definition']
    @description  = row['description']
    @column_count = row['column_count'].try(:to_i)
    @row_count = row['row_count'].try(:to_i)
    @table_type = row['table_type']
    @last_analyzed = row['last_analyzed'].try(:utc)
    @disk_size = row['disk_size'].try(:to_i)
    @partition_count = row['partition_count'].try(:to_i)
  end

  def entity_type_name
    'dataset_statistics'
  end

  def self.build_for(dataset, account)
    if dataset.kind_of?(ChorusView)
      build_for_chorus_view(dataset, account)
    elsif dataset.kind_of?(HdfsDataset)
      build_for_hdfs_dataset(dataset)
    else
      build_for_db_dataset(account, dataset)
    end
  end

  private

  def self.build_for_db_dataset(account, dataset)
    connection = dataset.schema.connect_with(account)
    metadata = connection.metadata_for_dataset(dataset.name)

    if metadata
      if metadata['partition_count'].to_i > 0
        metadata['disk_size'] = partition_disk_size(connection, dataset.name, metadata)
      end

      self.new(metadata)
    end
  end

  def self.build_for_chorus_view(dataset, account)
    result = dataset.schema.connect_with(account).prepare_and_execute_statement(dataset.query, :describe_only => true)
    self.new('column_count' => result.columns.count)
  end

  def self.build_for_hdfs_dataset(dataset)
    HdfsDatasetStatistics.new('file_mask' => dataset.file_mask)
  end

  def self.partition_disk_size(connection, name, metadata)
    connection.partitions_disk_size(name) + metadata['disk_size'].to_i
  end
end
