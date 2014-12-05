module Sequel
  module AdditionalJdbcDrivers
    MAP =  {
        mariadb: ->(db) { org.mariadb.jdbc.Driver },
        teradata: ->(db) { com.teradata.jdbc.TeraDriver },
        vertica: ->(db) { com.vertica.jdbc.Driver }
    }

    MAP.each do |key, driver|
      ::Sequel::JDBC::DATABASE_SETUP[key] = driver
    end
  end
end
