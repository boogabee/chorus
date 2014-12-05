module Workspaces
  class CsvImportsController < ApplicationController
    wrap_parameters :csv_import, :exclude => []
    before_filter :demo_mode_filter, :only => [:create]

    def create
      csv_file = CsvFile.find params[:csv_id]
      authorize! :create, csv_file

      file_params = params[:csv_import].slice(:types, :delimiter, :column_names, :has_header, :to_table)
      csv_file.update_attributes!(file_params)

      import_params = params[:csv_import].slice(:to_table, :truncate, :new_table).merge(:csv_file => csv_file, :workspace_id => params[:workspace_id], :user => current_user)
      CsvImport.create!(import_params)
      present [], :status => :created
    end
  end
end