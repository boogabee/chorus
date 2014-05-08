module PostgresLikeDataSourceBehavior
  extend ActiveSupport::Concern

  included do
    after_destroy :enqueue_destroy_databases
  end

  def refresh_databases(options ={})
    found_databases = []
    rows = connect_with(owner_account).prepare_and_execute_statement(database_and_role_sql).hashes
    database_account_groups = rows.inject({}) do |groups, row|
      groups[row["database_name"]] ||= []
      groups[row["database_name"]] << row["db_username"]
      groups
    end

    database_account_groups.each do |database_name, db_usernames|
      database = databases.find_or_initialize_by_name(database_name)

      if database.invalid?
        databases.delete(database)
        next
      end

      database.update_attributes!({:stale_at => nil}, :without_protection => true)
      database_accounts = accounts.where(:db_username => db_usernames)
      if database.data_source_accounts.sort != database_accounts.sort
        database.data_source_accounts = database_accounts
        QC.enqueue_if_not_queued("GpdbDatabase.reindex_datasets", database.id) if database.datasets.count > 0
      end
      found_databases << database
    end
    refresh_schemas options unless options[:skip_schema_refresh]
  rescue GreenplumConnection::QueryError => e
    Chorus.log_error "Could not refresh database: #{e.message} on #{e.backtrace[0]}"
  ensure
    (databases.not_stale - found_databases).each(&:mark_stale!) if options[:mark_stale]
  end

  def refresh_schemas(options={})
    databases.not_stale.each do |database|
      begin
        Schema.refresh(owner_account, database, options.reverse_merge(:refresh_all => true))
      rescue GreenplumConnection::DatabaseError => e
        Chorus.log_debug "Could not refresh database #{database.name}: #{e.message} #{e.backtrace.to_s}"
      end
    end
  end

  private

  def account_names
    accounts.pluck(:db_username)
  end

  def database_and_role_sql
    roles = Arel::Table.new("pg_catalog.pg_roles", :as => "r")
    databases = Arel::Table.new("pg_catalog.pg_database", :as => "d")

    roles.join(databases).
        on(Arel.sql("has_database_privilege(r.oid, d.oid, 'CONNECT')")).
        where(
        databases[:datname].not_eq("postgres").
            and(databases[:datistemplate].eq(false)).
            and(databases[:datallowconn].eq(true)).
            and(roles[:rolname].in(account_names))
    ).project(
        roles[:rolname].as("db_username"),
        databases[:datname].as("database_name")
    ).to_sql
  end

  def connection_class
    GreenplumConnection
  end

  def enqueue_destroy_databases
    QC.enqueue_if_not_queued("GpdbDatabase.destroy_databases", id)
  end
end
