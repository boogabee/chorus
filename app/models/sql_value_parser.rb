class SqlValueParser
  def initialize(result_set, options = {})
    @result_set = result_set
    @options = options
  end

  def string_value(index)
    type = meta_data.column_type_name(index+1)

    # greenplum float8#to_s gives us weird rounded numbers
    if type == "float8"
      @result_set.get_object(index+1).to_s
    else
      @result_set.get_string(index+1) || nil_value
    end
  end

  private

  def meta_data
    @meta_data ||= @result_set.meta_data
  end

  def nil_value
    @options[:nil_value].to_s
  end
end