class JdbcDataTypes
  # see Sequel #schema_column_type
  def self.pretty_category_name(db_type)
    case db_type
      when /\A(character( varying)?|n?(var)?char|n?text|string|clob)/io
        'STRING'
      when /\A(int(eger)?|(big|small|tiny|byte)int)/io
        'WHOLE_NUMBER'
      when /\Adate\z/io
        'DATETIME'
      when /\A((small)?datetime|timestamp( with(out)? time zone)?)(\(\d+\))?\z/io
        'DATETIME'
      when /\Atime( with(out)? time zone)?\z/io
        'DATETIME'
      when /\A(bool(ean)?)\z/io
        'BOOLEAN'
      when /\A(real|float|double( precision)?|double\(\d+,\d+\)( unsigned)?)\z/io
        'REAL_NUMBER'
      when /\A(?:(?:(?:num(?:ber|eric)?|decimal)(?:\(\d+,\s*(\d+|false|true)\))?))\z/io
        $1 && ['0', 'false'].include?($1) ? 'INTEGER' : 'REAL_NUMBER'
      when /bytea|blob|image|(var)?(binary|byte)/io
        'OTHER'
      when /\Aenum/io
        'OTHER'
      else
        'OTHER'
    end
  end
end