module Events
  class HdfsImportFailed < HdfsImportFinished
    has_additional_data :error_message, :file_name
  end
end
