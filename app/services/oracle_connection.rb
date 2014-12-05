if ChorusConfig.instance.oracle_configured?
  begin
    require_relative '../../lib/libraries/ojdbc6.jar'
  rescue LoadError
    Rails.logger.warn "Error loading Oracle driver"
  end
elsif ChorusConfig.instance.oracle_driver_expected_but_missing?
  Rails.logger.warn "Oracle driver ojdbc6.jar not found"
end

class OracleConnection < DataSourceConnection
  class DatabaseError < Error
    def error_type
      return @error_type if @error_type

      error_code = @exception.wrapped_exception && @exception.wrapped_exception.respond_to?(:get_error_code) && @exception.wrapped_exception.get_error_code
      Rails.logger.error "Oracle error code = #{error_code}"
      errortype = case error_code
        when 1017 then :INVALID_PASSWORD
        when 12514 then :DATABASE_MISSING
        when 17002 then :DATA_SOURCE_UNREACHABLE
        else :GENERIC
      end
      Rails.logger.error "Oracle error code type = #{errortype}"
      errortype
    end

    private

    def sanitize_message(message)
      # jdbc:oracle:thin:username/password@//host:port/database
      message.gsub(/\:[^\:]+\/.+@\/\//, ':xxxx/xxxx@//')
        .gsub('Java::JavaSql::', '')
    end
  end

  def verify_driver_configuration
    raise DriverNotConfigured.new('Oracle') unless ChorusConfig.instance.oracle_configured?
  end

  def db_url
    "jdbc:oracle:thin:@//#{@data_source.host}:#{@data_source.port}/#{@data_source.db_name}"
  end

  def db_options
    super.merge :identifier_input_method => nil
  end

  def version
    with_connection do |connection|
      connection.fetch(%Q{select * from v$version where banner like 'Oracle%'}).first.first[1]
    end.match(/((\d+\.)+\d+)/)[1]
  end

  def schemas
    with_connection { |connection| connection.fetch(SCHEMAS_SQL).map { |row| row[:name] } }
  end

  def schema_exists?(name)
    schemas.include? name
  end

  def table_exists?(name)
    with_connection { |connection| connection.table_exists?("#{schema_name}__#{name.to_s}".to_sym) }
  end

  def view_exists?(name)
    with_connection do |connection|
      connection[:ALL_VIEWS].select(:VIEW_NAME).where(:OWNER => schema_name, :VIEW_NAME => name).first.present?
    end
  end

  def datasets(options={})
    datasets_query(options) do |query|
      query.order(:name).limit(options[:limit]).all
    end
  end

  def datasets_count(options={})
    datasets_query(options) do |query|
      query.count
    end
  end

  def metadata_for_dataset(dataset_name)
    with_connection do |connection|
      connection.fetch(<<-SQL, :table_name => dataset_name, :schema_name => schema_name).first
        SELECT COUNT(*) AS column_count
        FROM ALL_TAB_COLUMNS
        WHERE TABLE_NAME = :table_name AND OWNER = :schema_name
      SQL
    end
  end

  def column_info(table_name, setup_sql)
    with_connection do |connection|
      connection.fetch(<<-SQL, :table => table_name, :schema => schema_name).all
        SELECT COLUMN_NAME as attname, DATA_TYPE as format_type, COLUMN_ID as attnum
        FROM ALL_TAB_COLUMNS
        WHERE TABLE_NAME = :table AND OWNER = :schema
        ORDER BY attnum
      SQL
    end
  end

  def primary_key_columns(table_name)
    with_connection do |connection|
      sql = <<-SQL
        SELECT cols.table_name, cols.column_name, cols.position, cons.status, cons.owner
        FROM all_constraints cons, all_cons_columns cols
        WHERE cols.table_name = '#{table_name}'
        AND cols.owner = '#{schema_name}'
        AND cons.constraint_type = 'P'
        AND cons.constraint_name = cols.constraint_name
        AND cons.owner = cols.owner
        ORDER BY cols.table_name, cols.position
      SQL
      connection.fetch(sql).map { |row| row[:column_name] }
    end
  end

  def create_sql_result(warnings, result_set)
    OracleSqlResult.new(:warnings => warnings, :result_set => result_set)
  end

  def self.error_class
    OracleConnection::DatabaseError
  end

  def visualization_sql_generator
    Visualization::SqlGenerator.new(:limit_type => :oracle).extend(Visualization::OracleSql)
  end

  private

  def datasets_query(options)
    with_connection do |connection|
      table_query = connection.select(Sequel.as('t', :type), Sequel.as(:TABLE_NAME, :name)).from(:ALL_TABLES).where(:OWNER => schema_name)
      view_query = connection.select(Sequel.as('v', :type), Sequel.as(:VIEW_NAME, :name)).from(:ALL_VIEWS).where(:OWNER => schema_name)
      if options[:name_filter]
        table_query = table_query.where(["REGEXP_LIKE(TABLE_NAME, :name_filter, 'i')", :name_filter => options[:name_filter]])
        view_query = view_query.where(["REGEXP_LIKE(VIEW_NAME, :name_filter, 'i')", :name_filter => options[:name_filter]])
      end
      datasets_query = table_query
      unless options[:tables_only]
        datasets_query = datasets_query.union(view_query)
      end

      yield datasets_query
    end
  end

  def schema_name
    @options[:schema]
  end

  SCHEMAS_SQL = <<-SQL
      SELECT DISTINCT OWNER as name
      FROM ALL_OBJECTS
      WHERE OBJECT_TYPE IN ('TABLE', 'VIEW') AND OWNER NOT IN ('OBE', 'SCOTT', 'DIP',
        'ORACLE_OCM', 'XS$NULL', 'MDDATA', 'SPATIAL_WFS_ADMIN_USR', 'SPATIAL_CSW_ADMIN_USR',
        'IX', 'SH', 'PM', 'BI', 'DEMO', 'HR1', 'OE1', 'XDBPM', 'XDBEXT', 'XFILES',
        'APEX_PUBLIC_USER', 'TIMESTEN', 'CACHEADM', 'PLS', 'TTHR', 'APEX_REST_PUBLIC_USER',
        'APEX_LISTENER', 'OE', 'HR', 'HR_TRIG', 'PHPDEMO', 'APPQOSSYS', 'WMSYS', 'OWBSYS_AUDIT',
        'OWBSYS', 'SYSMAN', 'EXFSYS', 'CTXSYS', 'XDB', 'ANONYMOUS', 'OLAPSYS', 'APEX_040200',
        'ORDSYS', 'ORDDATA', 'ORDPLUGINS', 'FLOWS_FILES', 'SI_INFORMTN_SCHEMA', 'MDSYS',
        'DBSNMP', 'OUTLN', 'MGMT_VIEW', 'SYSTEM', 'SYS')
  SQL

  DATASETS_SQL = <<-SQL
      SELECT * FROM (
        SELECT * FROM (
          SELECT 't' as type, TABLE_NAME AS name FROM ALL_TABLES WHERE OWNER = :schema AND REGEXP_LIKE(TABLE_NAME, :name_filter, 'i')
          UNION
          SELECT 'v' as type, VIEW_NAME AS name FROM ALL_VIEWS WHERE OWNER = :schema AND REGEXP_LIKE(VIEW_NAME, :name_filter, 'i'))
        ORDER BY name
      )
      WHERE rownum <= :limit
  SQL
end
