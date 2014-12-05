namespace :db do
  namespace :test do
    task :prepare => 'db:integration:load_structure'
  end

  task :seed_development => :environment do
    load Rails.root.join('db', 'development_seeds.rb')
  end

  def create_database_tasks(database_name)
    namespace database_name.to_sym do
      desc "Recreate the #{database_name} from an existent structure.sql file"
      task :load_structure => "db:#{database_name}:purge" do
        load_database_structure database_name
      end

      desc "Empty the #{database_name} database"
      task :purge => :environment do
        empty_test_database database_name
      end

      task :prepare => "db:#{database_name}:load_structure"
    end
  end

  def load_database_structure(database_name)
    current_config(:config => ActiveRecord::Base.configurations[database_name])
    Rake::Task[:"db:structure:load"].invoke
    Rake::Task[:"db:structure:load"].reenable
  ensure
    current_config(:config => nil)
  end

  def empty_test_database(database_name)
    abcs = ActiveRecord::Base.configurations
    case abcs[database_name]['adapter']
      when /mysql/
        ActiveRecord::Base.establish_connection(:test)
        ActiveRecord::Base.connection.recreate_database(abcs[database_name]['database'], mysql_creation_options(abcs[database_name]))
      when /postgresql/
        ActiveRecord::Base.clear_active_connections!
        drop_database(abcs[database_name])
        create_database(abcs[database_name])
      when /sqlite/
        dbfile = abcs[database_name]['database']
        File.delete(dbfile) if File.exist?(dbfile)
      when 'sqlserver'
        db = abcs.deep_dup[database_name]
        db_database = db['database']
        db['database'] = 'master'
        ActiveRecord::Base.establish_connection(db)
        ActiveRecord::Base.connection.recreate_database!(db_database)
      when "oci", "oracle"
        ActiveRecord::Base.establish_connection(database_name.to_sym)
        ActiveRecord::Base.connection.structure_drop.split(";\n\n").each do |ddl|
          ActiveRecord::Base.connection.execute(ddl)
        end
      when 'firebird'
        ActiveRecord::Base.establish_connection(database_name.to_sym)
        ActiveRecord::Base.connection.recreate_database!
      else
        raise "Task not supported by '#{abcs[database_name]['adapter']}'"
    end
  end

  %w{integration ci_jasmine ci_legacy ci_next}.each do |database_name|
     create_database_tasks(database_name)
  end
end