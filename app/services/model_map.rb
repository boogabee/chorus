module ModelMap
  UnknownEntityType = Class.new(StandardError)

  CLASS_NAME_MAP = {
    "hdfs_file" => "HdfsEntry"
  }

  def self.class_from_type(entity_type)
    raise UnknownEntityType.new("Invalid entity type") if entity_type.blank?

    class_name = CLASS_NAME_MAP[entity_type] || entity_type.to_s.camelcase
    class_name.constantize
  rescue NameError
    raise UnknownEntityType
  end

  def self.model_from_params(entity_type, entity_id)
    class_from_type(entity_type).find(entity_id)
  end
end
