class SchemaFunction
  attr_reader :schema_name, :function_name, :language, :return_type, :arg_names, :arg_types, :definition, :description

  def initialize(schema_name, func_name, lang, return_type, arg_names, arg_type, definition, description)
    @schema_name = schema_name
    @function_name = func_name
    @language = lang
    @return_type = return_type
    @arg_names = arg_names
    @arg_types = arg_type
    @definition = definition
    @description = description
  end

  def entity_type_name
    'schema_function'
  end
end
