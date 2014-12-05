class RenameOracleInstanceToOracleDataSource < ActiveRecord::Migration
  def up
    execute "UPDATE data_sources SET type = 'OracleDataSource' WHERE type = 'OracleInstance'"
  end

  def down
    execute "UPDATE data_sources SET type = 'OracleInstance' WHERE type = 'OracleDataSource'"
  end
end
