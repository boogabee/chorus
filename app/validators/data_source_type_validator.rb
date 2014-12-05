class DataSourceTypeValidator < ActiveModel::Validator
  include LicenseValidations

  def validate(record)
    with_license_validation(:limit_data_source_types?) do |license|
      record.errors.add(:data_source_type, :license_limit_exceeded) if limit_exceeded?(record)
    end
  end

  private

  def limit_exceeded?(record)
    unique_sources = (existing_types << record.license_type).uniq
    unique_sources.count > 1 && ( total_sources > 1 || record.new_record? )
  end

  def existing_types
    [
        DataSource.select(:type).uniq,
        HdfsDataSource.select('hdfs_version, version').uniq,
        GnipDataSource.first
    ].flatten.compact.map(&:license_type)
  end

  def total_sources
    [DataSource, HdfsDataSource, GnipDataSource].map(&:count).sum
  end

end
