class DatasetImportabilityPresenter < Presenter
  def to_hash
    if @model.importable?
      importable_hash
    else
      unimportable_hash
    end
  end

  private

  def importable_hash
    {
      :importability => true
    }
  end

  def unimportable_hash
    {
      :importability => false,
      :invalid_columns => format_invalid_columns,
      :supported_column_types => @model.supported_column_types
    }
  end

  def format_invalid_columns
    @model.invalid_columns.map do |column|
      "#{column[:column_name]} (#{column[:column_type]})"
    end
  end
end