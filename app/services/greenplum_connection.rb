class GreenplumConnection < PostgresLikeConnection

  def metadata_for_dataset(table_name)
    with_connection do |connection|
      relations = connection.from(Sequel.as(:pg_catalog__pg_class, :relations))
      schema_query = connection.from(Sequel.as(:pg_namespace, :schemas)).where(:nspname => schema_name).select(:oid)
      relations_in_schema = relations.where(:relnamespace => schema_query)
      query = relations_in_schema.where(:relations__relname => table_name)

      # Is it a view?
      query = query.left_outer_join(:pg_views, :viewname => :relname)

      # Is it an external table?
      query = query.left_outer_join(:pg_exttable, :pg_exttable__reloid => :relations__oid)

      # Last analyzed time
      query = query.left_outer_join(:pg_stat_last_operation, :objid => :relations__oid, :staactionname => 'ANALYZE')

      query = query.select(Sequel.as(:relations__reltuples, :row_count), Sequel.as(:relations__relname, :name),
                           Sequel.as(:pg_views__definition, :definition), Sequel.as(:relations__relnatts, :column_count),
                           Sequel.as(:pg_stat_last_operation__statime, :last_analyzed), Sequel.as(:relations__oid, :oid))

      partition_count_query = connection[:pg_partitions].where(:schemaname => schema_name, :tablename => table_name).select { count(schemaname) }
      query = query.select_append(Sequel.as(partition_count_query, :partition_count))

      query = query.select_append { obj_description(relations__oid).as('description') }

      table_type = Sequel.case(
          [
              [{:relations__relhassubclass => 't'}, 'MASTER_TABLE'],
              [{:relations__relkind => 'v'}, 'VIEW'],
              [{:pg_exttable__location => nil}, 'BASE_TABLE'],
              [Sequel.lit("position('gphdfs' in pg_exttable.location[1]) > 0"), 'HD_EXT_TABLE']
          ],
          'EXT_TABLE'
      )
      query = query.select_append(Sequel.as(table_type, :table_type))

      result = query_with_disk_size(query, connection)

      if result
        result[:row_count] = result[:row_count].to_i
        result[:disk_size] = result[:disk_size].to_i unless result[:disk_size] == 'unknown'
      end
      result
    end
  end

  def distribution_key_columns(table_name)
    with_connection do |connection|
      sql = <<-SQL
          SELECT attname
          FROM   (SELECT *, generate_series(1, array_upper(attrnums, 1)) AS rn
          FROM   gp_distribution_policy where localoid = '#{quote_identifier(schema_name)}.#{quote_identifier(table_name)}'::regclass
          ) y, pg_attribute WHERE attrelid = '#{quote_identifier(schema_name)}.#{quote_identifier(table_name)}'::regclass::oid AND attrnums[rn] = attnum ORDER by rn;
      SQL
      connection.fetch(sql).map { |row| row[:attname] }
    end
  end

  private

  def datasets_query(options)
    with_connection do |connection|
      query = connection.from(Sequel.as(:pg_catalog__pg_class, :relations)).select(Sequel.as(:relkind, 'type'), Sequel.as(:relname, 'name'), Sequel.as(:relhassubclass, 'master_table'))
      query = query.select_append do |o|
        o.`(%Q{('#{quote_identifier(schema_name)}."' || relations.relname || '"')::regclass})
      end
      query = query.join(:pg_namespace, :oid => :relnamespace)
      query = query.left_outer_join(:pg_partition_rule, :parchildrelid => :relations__oid, :relations__relhassubclass => 'f')
      query = query.where(:pg_namespace__nspname => schema_name)
      query = query.where(:relations__relkind => options[:tables_only] ? 'r' : ['r', 'v'])
      query = query.where(:relations__relstorage => ['h','a']) if options[:tables_only]
      query = query.where(%Q|"relations"."relhassubclass" = 't' OR "pg_partition_rule"."parchildrelid" is null|)
      query = query.where(%Q|"relations"."oid" NOT IN (SELECT "parchildrelid" FROM "pg_partition_rule")|)

      if options[:name_filter]
        query = query.where("\"relname\" ILIKE '%#{::DataSourceConnection.escape_like_string(options[:name_filter])}%' ESCAPE '#{::DataSourceConnection::LIKE_ESCAPE_CHARACTER}'")
      end

      yield query.qualify
    end
  rescue DatabaseError => e
    raise SqlPermissionDenied, e if e.message =~ /permission denied/i
    raise e
  end

  def build_distribution_clause(clause)
    clause
  end

  def version_prefix
    'Greenplum Database'
  end
end
