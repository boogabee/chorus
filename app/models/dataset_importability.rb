class DatasetImportability
  def initialize(dataset)
    @dataset = dataset
  end

  def importable?
    @dataset.kind_of?(GpdbDataset) || @dataset.kind_of?(PgDataset) || invalid_columns.empty?
  end

  def invalid_columns
    invalid_columns = []

    @dataset.column_data.each do |column|
      unless OracleDataTypes.greenplum_type_for(column.data_type)
        invalid_columns << {
          column_name: column.name,
          column_type: column.data_type
        }
      end
    end

    invalid_columns
  end

  def supported_column_types
    OracleDataTypes.supported_column_types
  end
end
