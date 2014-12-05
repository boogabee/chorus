require 'spec_helper'

describe LinkedTableauWorkfile do
  let(:model) { workfiles(:tableau) }
  let(:tableau_publication) { model.tableau_workbook_publication }

  it { should have_one(:tableau_workbook_publication).dependent(:destroy) }

  it "should have the url to the tableau workbook" do
    model.workbook_url.should == tableau_publication.workbook_url
  end

  it "should have the workbook name" do
    model.workbook_name.should == tableau_publication.name
  end

  context "when the publication is nil" do
    before do
      model.tableau_workbook_publication = nil
    end

    it "should not blow up for workbook url and name" do
      model.workbook_url.should be_nil
      model.workbook_name.should be_nil
    end
  end

  it "should have a content_type" do
    model.content_type.should == "tableau_workbook"
  end

  context "creating" do
    let(:user) { users(:owner) }

    it "should generate a TableauWorkfileCreated event" do
      set_current_user(user)

      workfile = LinkedTableauWorkfile.new({:file_name => 'tableau_workfile',
                                               :workspace => workspaces(:public),
                                               :owner => user,
                                               :tableau_workbook_publication => tableau_publication
                                              }, :as => :create)
      expect {
        workfile.save
      }.to change(Events::TableauWorkfileCreated, :count).by(1)

      event = Events::TableauWorkfileCreated.by(user).last
      event.workfile == workfile
      event.workspace.should == workspaces(:public)
      event.dataset.should == tableau_publication.dataset
      event.workbook_name.should == tableau_publication.name
    end
  end
end