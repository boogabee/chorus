class OrphanCleaner
  def self.clean
    HdfsEntry.where('hdfs_data_source_id IN (SELECT id FROM hdfs_data_sources WHERE deleted_at IS NOT NULL)').find_each do |entry|
      entry.destroy
    end

    HdfsDataset.where('hdfs_data_source_id IN (SELECT id FROM hdfs_data_sources WHERE deleted_at IS NOT NULL)').find_each do |dataset|
      dataset.destroy
    end

    GpdbDatabase.where('data_source_id IN (SELECT id FROM data_sources WHERE deleted_at IS NOT NULL)').find_each do |database|
      database.destroy
    end

    GpdbSchema.where('parent_id IN (SELECT id FROM databases WHERE deleted_at IS NOT NULL)').find_each do |schema|
      schema.destroy
    end

    OracleSchema.where("parent_id IN (SELECT id FROM data_sources WHERE type = 'OracleDataSource' AND deleted_at IS NOT NULL)").find_each do |schema|
      schema.destroy
    end

    RelationalDataset.where('schema_id IN (SELECT id FROM schemas WHERE deleted_at IS NOT NULL)').find_each do |dataset|
      dataset.destroy
    end
  end
end
