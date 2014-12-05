module ImportConsole
  module ImportsHelper
    def table_description(schema, table_name)
      description = ''
      return description unless schema
      description << schema.database.name + "." if schema.respond_to?(:database) && !schema.database.nil?
      description << schema.name + "." + table_name
    end

    def data_source_description_for_schema(schema)
      if schema
        data_source = schema.data_source
        if data_source
          data_source.host + ":" + data_source.port.to_s
        else
          "#{schema.name} has no data source"
        end
      else
        "No schema found."
      end
    end

    def link_to_table(dataset)
      "/#/datasets/#{dataset.id}"
    end

    def link_to_workspace_table(workspace, dataset)
      type = dataset.type == "ChorusView" ? "chorus_views" : "datasets"
      "/#/workspaces/#{workspace.id}/#{type}/#{dataset.id}"
    end

    def link_to_source(import_manager)
      source_dataset = import_manager.source_dataset
      description = table_description(source_dataset.schema, source_dataset.name)
      if import_manager.workspace_import?
        link = link_to_workspace_table(import_manager.workspace, source_dataset)
      else
        link = link_to_table(source_dataset)
      end
      link_to(description, link)
    end

    def link_to_destination(import_manager)
      to_table = import_manager.to_table
      schema_or_sandbox = import_manager.schema
      description = table_description(schema_or_sandbox, to_table)
      dest_table = schema_or_sandbox.datasets.find_by_name(to_table)
      if dest_table
        if import_manager.workspace_import?
          link_to(description, link_to_workspace_table(import_manager.workspace, dest_table))
        else
          link_to(description, link_to_table(dest_table))
        end
      else
        description
      end
    end

    def show_process
      yield || "Not found"
    rescue Exception
      "unknown"
    end
  end
end