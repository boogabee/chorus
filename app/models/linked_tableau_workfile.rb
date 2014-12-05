class LinkedTableauWorkfile < Workfile

  attr_accessible :tableau_workbook_publication, :as => :create

  has_one :tableau_workbook_publication, :dependent => :destroy
  delegate :workbook_url, :to => :tableau_workbook_publication, :allow_nil => true
  delegate :name, :to => :tableau_workbook_publication, :prefix => :workbook, :allow_nil => true

  def content_type
    "tableau_workbook"
  end

  private

  def create_workfile_created_event
    Events::TableauWorkfileCreated.by(current_user).add(
        :dataset => tableau_workbook_publication.dataset,
        :workfile => self,
        :workspace => workspace,
        :workbook_name => tableau_workbook_publication.name
    )
  end
end