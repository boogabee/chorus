class TableauWorkbookPublication < ActiveRecord::Base
  attr_accessible :dataset_id, :name, :workspace_id, :project_name

  belongs_to :dataset
  belongs_to :workspace
  belongs_to :linked_tableau_workfile

  after_create :create_created_event

  def workbook_url
    "http://#{base_url}/workbooks/#{name}"
  end

  def project_url
    "http://#{base_url}/workbooks?fe_project.name=#{project_name}"
  end

  def base_url
    base_url = ChorusConfig.instance['tableau.url']
    port = ChorusConfig.instance['tableau.port']
    base_url += ":#{port}" if port && port != 80
    base_url
  end

  private

  def create_created_event
    Events::TableauWorkbookPublished.by(current_user).add(
        :workbook_name => name,
        :dataset => dataset,
        :workspace => workspace,
        :workbook_url => workbook_url,
        :project_name => project_name,
        :project_url => project_url
    )
  end
end
