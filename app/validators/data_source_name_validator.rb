class DataSourceNameValidator < ActiveModel::Validator

  DATA_SOURCE_TYPES = [DataSource, HdfsDataSource, GnipDataSource]

  def validate(record)
    if record.name && unique_name?(record)
      record.errors.add(:name, :taken)
    end
  end

  private

  def unique_name?(record)
    DATA_SOURCE_TYPES.any? { |source_type|
      search = source_type.where('LOWER(name) = ?', record.name.downcase)
      search.reject { |model|
        model == record
      }.length > 0
    }
  end
end