module OracleDataTypes
  ORACLE_TO_PRETTY_CATEGORY_NAME_MAP = {
      'BFILE' => 'OTHER',
      'BINARY_DOUBLE' => 'REAL_NUMBER',
      'BINARY_FLOAT' => 'REAL_NUMBER',
      'BLOB' => 'OTHER',
      'CHAR' => 'STRING',
      'CLOB' => 'LONG_STRING',
      'DATE' => 'DATETIME',
      'DECIMAL' => 'REAL_NUMBER',
      'FLOAT' => 'REAL_NUMBER',
      'INT' => 'WHOLE_NUMBER',
      'LONG' => 'LONG_STRING',
      'LONG RAW' => 'OTHER',
      'MLSLABEL' => 'OTHER',
      'NCHAR' => 'STRING',
      'NCLOB' => 'LONG_STRING',
      'NUMBER' => 'WHOLE_NUMBER',
      'NVARCHAR2' => 'STRING',
      'RAW' => 'OTHER',
      'ROWID' => 'LONG_STRING',
      'TIMESTAMP' => 'DATETIME',
      'UROWID' => 'LONG_STRING',
      'VARCHAR' => 'STRING',
      'VARCHAR2' => 'STRING',
      'XMLTYPE' => 'OTHER',
      'TIMESTAMP WITH TIME ZONE' => 'DATETIME',
      'TIMESTAMP WITH LOCAL TIME ZONE' => 'DATETIME',
  }

  ORACLE_TO_GPDB_TYPE_MAP = {
      'BINARY_DOUBLE' => 'double precision',
      'BINARY_FLOAT' => 'double precision',
      'CHAR' => 'character(1)',
      'CLOB' => 'text',
      'DATE' => 'timestamp without time zone',
      'LONG' => 'text',
      'DECIMAL' => 'double precision',
      'FLOAT' => 'double precision',
      'INT' => 'numeric',
      'NCHAR' => 'character(1)',
      'NCLOB' => 'text',
      'NUMBER' => 'numeric',
      'NVARCHAR2' => 'character varying',
      'ROWID' => 'text',
      'TIMESTAMP' => 'timestamp without time zone',
      'UROWID' => 'text',
      'VARCHAR' => 'character varying',
      'VARCHAR2' => 'character varying',
      'TIMESTAMP WITH TIME ZONE' => 'timestamp with time zone',
      'TIMESTAMP WITH LOCAL TIME ZONE' => 'timestamp without time zone'
  }

  def self.greenplum_type_for(oracle_type)
    ORACLE_TO_GPDB_TYPE_MAP[without_specification(oracle_type)]
  end

  def self.pretty_category_name(oracle_type)
    ORACLE_TO_PRETTY_CATEGORY_NAME_MAP[without_specification(oracle_type).upcase]
  end

  def self.supported_column_types
    ORACLE_TO_GPDB_TYPE_MAP.keys
  end

  private

  def self.without_specification(type)
    type.split('(').first
  end
end
