module SandboxSchema
  extend ActiveSupport::Concern

  included do
    #imports must be cancelled before we nullify the sandbox_id on workspaces
    before_destroy :cancel_imports

    attr_accessible :database
    alias_attribute :database, :parent
    delegate :data_source, :account_for_user!, :to => :database

    has_many :workspaces, :foreign_key => :sandbox_id, :dependent => :nullify

    has_many :imports, class_name: 'SchemaImport', foreign_key: 'schema_id'
    has_many :imports_via_workspaces, :through => :workspaces, :source => :all_imports

    has_many :workfiles_as_execution_location, :class_name => 'Workfile', :as => :execution_location, :dependent => :nullify
  end

  def disk_space_used(account)
    @disk_space_used ||= connect_with(account).disk_space_used
    @disk_space_used == :error ? nil : @disk_space_used
  rescue Exception => e
    @disk_space_used = :error
    raise e if (e.respond_to?(:error_type) && e.error_type == :INVALID_PASSWORD)
    nil
  end

  def stored_functions(account)
    results = connect_with(account).functions

    #This would be a lot easier if the schema_function_query could use ARRAY_AGG,
    #but it is not available on GPDB 4.0

    reduced_results = results.reduce [-1, []] do |last, result|
      record = result.values
      last_record_id = last[0]
      functions = last[1]
      current_function = functions.last
      current_function_types = current_function[5] if current_function
      arg_type = record[5]

      if current_function and record[0] == last_record_id
        current_function_types << arg_type
      else
        record[5] = [arg_type]
        functions << record
      end

      [record[0], last[1]]
    end

    reduced_results.last.map do |record|
      SchemaFunction.new(name, *record[1..7])
    end
  end

  private

  def cancel_imports
    imports.unfinished.each do |import|
      import.cancel(false, 'Source/Destination of this import was deleted')
    end
    imports_via_workspaces.unfinished.each do |import|
      import.cancel(false, 'Source/Destination of this import was deleted')
    end
  end
end
