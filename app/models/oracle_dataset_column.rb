class OracleDatasetColumn < DatasetColumn
  def supported?
    !!OracleDataTypes.greenplum_type_for(data_type.upcase)
  end

  def gpdb_data_type
    OracleDataTypes.greenplum_type_for(data_type.upcase)
  end
end
