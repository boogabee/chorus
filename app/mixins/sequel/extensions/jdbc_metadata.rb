module Sequel
  module JdbcMetadata
    def get_metadata(*args)
      synchronize do |c|
        c.getMetaData.send(*args)
      end
    end

    def process_metadata(*args, &block)
      metadata(*args, &block)
    end

    private

    def schema_parse_table_skip?(h, schema)
      false
    end
  end

  Database.register_extension(:jdbc_metadata, JdbcMetadata)
end