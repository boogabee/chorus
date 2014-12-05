module ExistingDataSourcesValidator
  def self.log(*args)
    puts *args
  end

  def self.run(data_source_types)
    log "Searching for duplicate data source names..."

    existing_data_source_types = data_source_types.select { |data_source|
      ActiveRecord::Base.connection.table_exists? data_source.table_name
    }

    invalid_data_sources = find_invalid_data_sources(existing_data_source_types)

    if invalid_data_sources.empty?
      return true
    else
      log "Duplicate data source names found: #{invalid_data_sources.uniq.join(", ")}"
      return false
    end
  end

  private

  def self.find_invalid_data_sources(klasses)
    names = []
    klasses.each do |klass|
      names += ActiveRecord::Base.connection.exec_query("select * from #{klass.table_name}").reject { |record| record["deleted_at"] }.map { |record| record["name"] }
    end

    names.reject { |name| names.count(name) == 1 }
  end
end