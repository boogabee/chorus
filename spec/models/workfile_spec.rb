require 'spec_helper'

describe Workfile do
  it_behaves_like "a notable model" do
    let!(:note) do
      Events::NoteOnWorkfile.create!({
          :actor => users(:owner),
          :workfile => model,
          :body => "This is the body"
      }, :as => :create)
    end

    let!(:model) { FactoryGirl.create(:workfile) }
  end

  it { should respond_to(:create_new_version) }
  it { should respond_to(:attempt_data_source_connection) }
  it { should respond_to(:remove_draft) }

  describe "validations" do
    it { should validate_presence_of :file_name }
    it { should validate_presence_of :workspace }
    it { should validate_presence_of :owner }

    context "normalize the file name" do
      let!(:another_workfile) { FactoryGirl.create(:workfile, :file_name => 'workfile.sql') }
      let(:workfile) { Workfile.new(:file_name => "workfile.sql") }
      let(:workspace) { another_workfile.workspace }
      let(:resolve_name_conflicts) { false }

      before do
        workfile.resolve_name_conflicts = resolve_name_conflicts
        workfile.workspace = another_workfile.workspace
        workfile.owner = another_workfile.owner
      end

      context "when not resolving name conflicts" do
        it "is not valid" do
          workfile.should_not be_valid
          workfile.file_name.should == "workfile.sql"
        end
      end

      context "first conflict" do
        let(:resolve_name_conflicts) { true }
        it "renames and turns the workfile valid" do
          workfile.should be_valid
          workfile.file_name.should == 'workfile_1.sql'
        end
      end

      context "multiple conflicts" do
        let(:resolve_name_conflicts) { true }
        let!(:another_workfile_2) { FactoryGirl.create(:workfile, :workspace => workspace, :file_name => 'workfile.sql', :resolve_name_conflicts => true) }

        it "increases the name suffix number" do
          workfile.resolve_name_conflicts = true
          workfile.should be_valid
          workfile.file_name.should == 'workfile_2.sql'
        end
      end
    end
  end

  describe "name uniqueness validation" do
    let(:workspace) { workspaces(:public) }
    let(:other_workspace) { workspaces(:private) }
    let(:existing_workfile) { workspace.workfiles.first! }

    it "is invalid if a workfile in the workspace has the same name" do
      new_workfile = FactoryGirl.build(:workfile, :file_name => existing_workfile.file_name, :workspace => workspace)
      new_workfile.should_not be_valid
      new_workfile.should have_error_on(:file_name)
    end

    it "enforces uniqueness only among non-deleted workfiles" do
      stub(Alpine::API).delete_work_flow
      existing_workfile.destroy
      new_workfile = FactoryGirl.build(:workfile, :file_name => existing_workfile.file_name, :workspace => workspace)
      new_workfile.should be_valid
    end

    it "is valid if a workfile in another workspace has the same name" do
      new_workfile = FactoryGirl.build(:workfile, :file_name => existing_workfile.file_name, :workspace => other_workspace)
      new_workfile.should be_valid
    end

    it "is invalid if you change a name to an existing name" do
      new_workfile = FactoryGirl.build(:workfile, :file_name => 'totally_unique', :workspace => workspace)
      new_workfile.should be_valid
      new_workfile.file_name = existing_workfile.file_name
      new_workfile.should_not be_valid
    end
  end

  describe "associations" do
    it { should belong_to :owner }
    it { should have_many :activities }
    it { should have_many :events }
    it { should have_many :notes }
    it { should have_many :comments }

    describe "#notes" do
      let(:workfile) { workfiles(:private) }
      let(:author) { workfile.owner }

      it 'returns notes' do
        set_current_user(author)
        note = Events::NoteOnWorkfile.create!({:note_target => workfile, :body => "note on a workfile"}, :as => :create)
        workfile.reload
        workfile.notes.first.should be_a(Events::NoteOnWorkfile)
        workfile.notes.should == [note]
      end
    end

    it "destroys dependent versions" do
      workfile = workfiles(:public)
      versions = workfile.versions
      versions.length.should > 0

      workfile.destroy
      versions.each do |version|
        WorkfileVersion.find_by_id(version.id).should be_nil
      end
    end
  end

  describe "search fields" do
    it "indexes text fields" do
      Workfile.should have_searchable_field :file_name
      Workfile.should have_searchable_field :description
      Workfile.should have_searchable_field :version_comments
    end
  end

  describe "entity_type_name" do
    it "should return 'workfile'" do
      Workfile.new.entity_type_name.should == 'workfile'
    end
  end

  describe "copy" do
    let(:workfile) { workfiles(:public) }
    let(:workspace) { workspaces(:private) }
    let(:user) { users(:admin) }

    it "copies the associated data" do
      new_workfile = workfile.copy(user, workspace)
      new_workfile.file_name.should == workfile.file_name
      new_workfile.description.should == workfile.description
      new_workfile.workspace.should == workspace
      new_workfile.owner.should == user
    end

    it "copies any additional_data" do
      workfile.additional_data["something"] = "here"
      new_workfile = workfile.copy(user, workspace)
      new_workfile.additional_data["something"].should == "here"
    end

    it "should copy file to new name if new name is provided" do
      test_name = "whatever.txt"
      file = workfile.copy(user,workspace,test_name)
      file.file_name.should == test_name
    end
  end

  describe "copy!" do
    let(:workfile) { workfiles(:public) }
    let(:workspace) { workspaces(:private) }
    let(:user) { users(:admin) }

    it "copies stuff & saves the new workfile" do
      mock.proxy(workfile).copy(user, workspace, 'fooo')
      new_workfile = workfile.copy!(user, workspace, 'fooo')
      new_workfile.should be_persisted
    end

    it "can throw errors" do
      expect {
        workfile.copy!(user, workspace, "////")
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "create" do
    let(:workspace) { workspaces(:empty_workspace) }
    let(:user) { users(:owner) }

    it 'updates has_added_workfile on the workspace to true' do
      workspace.has_added_workfile.should be_false
      Workfile.build_for(:workspace => workspace, :owner => user, :file_name => 'test.sql').save!
      workspace.reload.has_added_workfile.should be_true
    end

    it 'makes a WorkfileCreated event' do
      set_current_user(user)
      description = 'i am a description'
      expect {
        Workfile.build_for(:workspace => workspace, :owner => user, :file_name => 'test.sql', :description => description).save!
      }.to change(Events::WorkfileCreated, :count).by(1)
      event = Events::WorkfileCreated.by(user).last
      event.workfile.description.should == description
      event.additional_data['commit_message'].should == description
      event.workspace.should == workspace
    end

    context 'when file_name is invalid' do
      it 'has a validation error rather than exploding' do
        workfile = Workfile.build_for(:workspace => workspace, :owner => user, :file_name => 'a/test.sql')
        workfile.save
        workfile.should have_error_on(:file_name)
      end
    end

  end

  describe 'user_modified_at' do
    let(:workfile) { workfiles(:public) }

    it 'does not update when adding tags' do
      expect do
        workfile.tag_list=(['garden', 'gnomes'])
      end.not_to change { workfile.user_modified_at }
    end

    it 'does not update when changing execution schema' do
      schema = schemas(:default)
      expect do
        workfile.execution_schema = schema
        workfile.save
      end.not_to change { workfile.user_modified_at }
    end

    it "updates on create" do
      workfile = FactoryGirl.create(:workfile)
      workfile.user_modified_at.should_not be_nil
    end
  end

  it_should_behave_like "taggable models", [:workfiles, :public]

  it_behaves_like 'a soft deletable model' do
    let(:model) { workfiles(:public) }
  end

  describe "changing the extension" do
    subject { workfile.update_attributes(:file_name => new_file_name) }

    context "renaming a text file to .sql" do
      let(:workfile) { workfiles("text.txt") }
      let(:new_file_name) { 'ham.sQl' }

      it "changes the content_type to 'sql'" do
        subject
        workfile.reload.content_type.should == 'sql'
      end
    end

    context "renaming a .png file to .sql" do
      let(:workfile) { workfiles("image.png") }
      let(:new_file_name) { 'ham.sql' }

      it "does not change the content_type" do
        expect do
          subject
        end.not_to change(workfile, :content_type)
        workfile.reload.content_type.should == 'image'
      end
    end

    context "renaming a sql file to .txt" do
      let(:workfile) { workfiles("sql.sql") }
      let(:new_file_name) { 'ham.tXt' }

      it "changes the content_type to 'txt'" do
        subject
        workfile.reload.content_type.should == 'text'
      end
    end

    context "renaming a sql file to .png" do
      let(:workfile) { workfiles("sql.sql") }
      let(:new_file_name) { 'ham.png' }

      it "leaves the content_type alone" do
        subject
        workfile.reload.content_type.should == 'sql'
      end
    end
  end
end
