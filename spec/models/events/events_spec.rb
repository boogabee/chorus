require "spec_helper"

require_relative "helpers"

describe "Event types" do
  extend EventHelpers

  let(:actor) { users(:owner) }
  let(:gpdb_data_source) { data_sources(:default) }
  let(:hdfs_data_source) { hdfs_data_sources(:hadoop) }
  let(:gnip_data_source) { gnip_data_sources(:default) }
  let(:user) { users(:the_collaborator) }
  let(:workfile) { workfiles(:public) }
  let(:workspace) { workfile.workspace }
  let(:dataset) { datasets(:view) }
  let(:destination_dataset) { datasets(:table) }
  let(:hdfs_entry) { hdfs_data_source.hdfs_entries.create!(:path => "/any/path/should/work.csv")}

  let(:chorus_view) { datasets(:chorus_view) }

  describe "ChorusViewCreated" do
    subject do
      Events::ChorusViewCreated.add(
          :actor => actor,
          :dataset => chorus_view,
          :source_object => dataset,
          :workspace => workspace
      )
    end

    its(:action) { should == "ChorusViewCreated" }
    its(:targets) { should == {:dataset => chorus_view, :source_object => dataset, :workspace => workspace} }

    it_creates_activities_for { [actor, chorus_view, dataset, workspace] }
    it_does_not_create_a_global_activity
  end

  describe "ViewCreated" do
    subject do
      Events::ViewCreated.add(
          :actor => actor,
          :dataset => dataset,
          :source_dataset => chorus_view,
          :workspace => workspace
      )
    end

    its(:action) { should == "ViewCreated" }
    its(:targets) { should == {:dataset => dataset, :source_dataset => chorus_view, :workspace => workspace} }

    it_creates_activities_for { [actor, chorus_view, dataset, workspace] }
    it_does_not_create_a_global_activity
  end

  describe "ChorusViewChanged" do
    subject do
      Events::ChorusViewChanged.add(
          :actor => actor,
          :workspace => workspace,
          :dataset => chorus_view
      )
    end

    its(:action) { should == "ChorusViewChanged" }
    its(:targets) { should == {:dataset => chorus_view, :workspace => workspace} }

    it_creates_activities_for { [actor, workspace, chorus_view] }
    it_does_not_create_a_global_activity
  end

  describe "HdfsDataSourceCreated" do
    subject do
      Events::HdfsDataSourceCreated.add(
          :actor => actor,
          :hdfs_data_source => hdfs_data_source
      )
    end

    its(:action) { should == "HdfsDataSourceCreated" }
    its(:hdfs_data_source) { should == hdfs_data_source }
    its(:targets) { should == {:hdfs_data_source => hdfs_data_source} }

    it_creates_activities_for { [actor, hdfs_data_source] }
    it_creates_a_global_activity
  end

  describe "GnipDataSourceCreated" do
    subject do
      Events::GnipDataSourceCreated.add(
          :actor => actor,
          :gnip_data_source => gnip_data_source
      )
    end

    its(:action) { should == "GnipDataSourceCreated" }
    its(:gnip_data_source) { should == gnip_data_source }
    its(:targets) { should == {:gnip_data_source => gnip_data_source} }

    it_creates_activities_for { [actor, gnip_data_source] }
    it_creates_a_global_activity
  end

  describe "DataSourceChangedOwner" do
    subject do
      Events::DataSourceChangedOwner.add(
          :actor => actor,
          :data_source => gpdb_data_source,
          :new_owner => user
      )
    end

    its(:data_source) { should == gpdb_data_source }
    its(:new_owner) { should == user }
    its(:targets) { should == {:data_source => gpdb_data_source, :new_owner => user} }

    it_creates_activities_for { [user, gpdb_data_source] }
    it_creates_a_global_activity
  end

  describe "DataSourceChangedName" do
    subject do
      Events::DataSourceChangedName.add(
          :actor => actor,
          :data_source => gpdb_data_source,
          :old_name => "brent",
          :new_name => "brenda"
      )
    end

    its(:data_source) { should == gpdb_data_source }
    its(:old_name) { should == "brent" }
    its(:new_name) { should == "brenda" }

    its(:targets) { should == {:data_source => gpdb_data_source} }
    its(:additional_data) { should == {'old_name' => "brent", 'new_name' => "brenda"} }

    it_creates_activities_for { [actor, gpdb_data_source] }
    it_creates_a_global_activity
  end

  describe "HdfsDataSourceChangedName" do
    subject do
      Events::HdfsDataSourceChangedName.add(
          :actor => actor,
          :hdfs_data_source => hdfs_data_source,
          :old_name => "brent",
          :new_name => "brenda"
      )
    end

    its(:hdfs_data_source) { should == hdfs_data_source }
    its(:old_name) { should == "brent" }
    its(:new_name) { should == "brenda" }

    its(:targets) { should == {:hdfs_data_source => hdfs_data_source} }
    its(:additional_data) { should == {'old_name' => "brent", 'new_name' => "brenda"} }

    it_creates_activities_for { [actor, hdfs_data_source] }
    it_creates_a_global_activity
  end

  describe "WORKSPACE_CREATED" do
    context "public workspace" do
      before do
        workspace.public = true
      end

      subject do
        Events::PublicWorkspaceCreated.add(
          :actor => actor,
          :workspace => workspace
        )
      end

      its(:workspace) { should == workspace }

      its(:targets) { should == { :workspace => workspace } }

      it_creates_activities_for { [actor, workspace] }
      it_creates_a_global_activity
    end

    context "private workspace" do
      before do
        workspace.public = false
      end

      subject do
        Events::PrivateWorkspaceCreated.add(
          :actor => actor,
          :workspace => workspace
        )
      end

      its(:workspace) { should == workspace }

      its(:targets) { should == { :workspace => workspace } }

      it_creates_activities_for { [actor, workspace] }
      it_does_not_create_a_global_activity
    end
  end

  describe "WorkspaceMakePublic" do
    before do
      workspace.public = false
    end

    subject do
      Events::WorkspaceMakePublic.add(
        :actor => actor,
        :workspace => workspace
      )
    end

    its(:workspace) { should == workspace }

    its(:targets) { should == { :workspace => workspace } }

    it_creates_activities_for { [actor, workspace] }
    it_creates_a_global_activity
  end

  describe "WorkspaceMakePrivate" do
    before do
      workspace.public = true
    end

    subject do
      Events::WorkspaceMakePrivate.add(
        :actor => actor,
        :workspace => workspace
      )
    end

    its(:workspace) { should == workspace }

    its(:targets) { should == { :workspace => workspace } }

    it_creates_activities_for { [actor, workspace] }
    it_does_not_create_a_global_activity
  end

  describe "WorkspaceArchived" do
    subject do
      Events::WorkspaceArchived.add(
          :actor => actor,
          :workspace => workspace
      )
    end

    its(:workspace) { should == workspace }

    its(:targets) { should == { :workspace => workspace } }

    it_creates_activities_for { [actor, workspace] }
    it_does_not_create_a_global_activity
  end

  describe "WorkspaceUnarchived" do
    subject do
      Events::WorkspaceUnarchived.add(
          :actor => actor,
          :workspace => workspace
      )
    end

    its(:workspace) { should == workspace }

    its(:targets) { should == { :workspace => workspace } }

    it_creates_activities_for { [actor, workspace] }
    it_does_not_create_a_global_activity
  end

  describe "WorkfileCreated" do
    subject do
      Events::WorkfileCreated.add(
          :actor => actor,
          :workfile => workfile,
          :workspace => workspace,
          :commit_message => 'new Commit message'
      )
    end

    its(:workfile) { should == workfile }
    its(:workspace) { should == workspace }

    its(:targets) { should == {:workfile => workfile, :workspace => workspace} }
    its(:additional_data) { should == {"commit_message" => 'new Commit message'} }

    it_creates_activities_for { [actor, workfile, workspace] }
    it_does_not_create_a_global_activity
  end

  describe "SourceTableCreated" do
    subject do
      Events::SourceTableCreated.add(
          :actor => actor,
          :dataset => dataset,
          :workspace => workspace
      )
    end

    its(:dataset) { should == dataset }
    its(:targets) { should == {:dataset => dataset, :workspace => workspace} }

    it_creates_activities_for { [actor, dataset, workspace] }
    it_does_not_create_a_global_activity
  end

  describe "UserAdded" do
    subject do
      Events::UserAdded.add(
          :actor => actor,
          :new_user => user
      )
    end

    its(:new_user) { should == user }
    its(:targets) { should == {:new_user => user} }

    it_creates_activities_for { [actor, user] }
    it_creates_a_global_activity
  end

  describe "WorkspaceAddSandbox" do
    subject do
      Events::WorkspaceAddSandbox.add(
          :actor => actor,
          :workspace => workspace
      )
    end

    its(:targets) { should == {:workspace => workspace} }

    it_creates_activities_for { [actor, workspace] }
    it_does_not_create_a_global_activity
  end

  describe "HDFS file/directory as external table events" do
    [Events::HdfsFileExtTableCreated,
     Events::HdfsDirectoryExtTableCreated].each do |klass|
      subject do
        klass.add(
            :actor => actor,
            :workspace => workspace,
            :hdfs_entry => hdfs_entry,
            :dataset => dataset
        )
      end

      its(:dataset) { should == dataset }
      its(:hdfs_entry) { should == hdfs_entry }

      its(:targets) { should == {:dataset => dataset, :hdfs_entry => hdfs_entry, :workspace => workspace} }

      it_creates_activities_for { [actor, dataset, workspace, hdfs_entry] }
    end
  end

  describe "HDFS as external table with file expression event" do
    subject do
      Events::HdfsPatternExtTableCreated.add(
          :actor => actor,
          :workspace => workspace,
          :hdfs_entry => hdfs_entry,
          :dataset => dataset,
          :file_pattern => '*.csv'
      )
    end

    its(:dataset) { should == dataset }
    its(:hdfs_entry) { should == hdfs_entry }

    its(:targets) { should == {:dataset => dataset, :hdfs_entry => hdfs_entry, :workspace => workspace} }

    it_creates_activities_for { [actor, dataset, workspace, hdfs_entry] }

    its(:additional_data) { should == {'file_pattern' => '*.csv'}}
  end

  describe "FileImportCreated" do
    subject do
      Events::FileImportCreated.add(
          :actor => actor,
          :dataset => dataset,
          :file_name => 'import.csv',
          :import_type => 'file',
          :workspace => workspace,
          :destination_table => dataset.name
      )
    end

    its(:dataset) { should == dataset }
    its(:targets) { should == {:workspace => workspace, :dataset => dataset} }
    its(:additional_data) { should == {'file_name' => "import.csv", 'import_type' => "file", 'destination_table' => dataset.name } }

    it_creates_activities_for { [actor, workspace, dataset] }
    it_does_not_create_a_global_activity
  end

  describe "FILE_IMPORT_SUCCESS" do
    subject do
      Events::FileImportSuccess.add(
          :actor => actor,
          :dataset => dataset,
          :file_name => 'import.csv',
          :import_type => 'file',
          :workspace => workspace
      )
    end

    its(:dataset) { should == dataset }
    its(:targets) { should == {:workspace => workspace, :dataset => dataset} }
    its(:additional_data) { should == {'file_name' => "import.csv", 'import_type' => "file"} }

    it_creates_activities_for { [actor, workspace, dataset] }
    it_does_not_create_a_global_activity
  end

  describe "WorkspaceImportFailed" do
    let(:source_dataset) {datasets(:other_table)}
    let!(:workspace_association) { workspace.source_datasets << source_dataset }
    subject do
      Events::WorkspaceImportFailed.add(
        :actor => actor,
        :source_dataset => source_dataset,
        :destination_table => 'test',
        :workspace => workspace,
        :error_message => 'Flying Monkey Attack again',
        :dataset => destination_dataset
      )
    end

    its(:targets) { should == {:workspace => workspace, :source_dataset => source_dataset, :dataset => destination_dataset} }
    its(:additional_data) { should == {'destination_table' => 'test', 'error_message' => 'Flying Monkey Attack again'} }

    it "has a workspace in the source_dataset" do
      subject.source_dataset.bound_workspaces.should include(workspace)
    end

    it_creates_activities_for { [actor, workspace, source_dataset, destination_dataset] }
    it_does_not_create_a_global_activity
  end

  describe "WorkspaceImportSuccess" do
    let(:source_dataset) { datasets(:other_table) }
    let!(:workspace_association) { workspace.source_datasets << source_dataset }
    subject do
      Events::WorkspaceImportSuccess.add(
        :actor => actor,
        :dataset => dataset,
        :source_dataset => source_dataset,
        :workspace => workspace
      )
    end

    its(:dataset) { should == dataset }
    its(:targets) { should == {:workspace => workspace, :dataset => dataset, :source_dataset => source_dataset} }

    it "has a workspace in the source_dataset" do
      subject.source_dataset.bound_workspaces.should include(workspace)
    end

    it_creates_activities_for { [actor, workspace, dataset, source_dataset] }
    it_does_not_create_a_global_activity

  end

  describe "ImportScheduleUpdated" do
    let(:source_dataset) { datasets(:other_table) }
    let!(:workspace_association) { workspace.source_datasets << source_dataset }
    subject do
      Events::ImportScheduleUpdated.add(
          :actor => actor,
          :dataset => dataset,
          :source_dataset => source_dataset,
          :workspace => workspace,
          :destination_table => dataset.name
      )
    end

    its(:dataset) { should == dataset }
    its(:targets) { should == {:workspace => workspace, :dataset => dataset, :source_dataset => source_dataset} }
    its(:additional_data) { should == { 'destination_table' => dataset.name } }

    it_creates_activities_for { [actor, workspace, dataset, source_dataset] }
    it_does_not_create_a_global_activity
  end

  describe "ImportScheduleDeleted" do
    let(:source_dataset) { datasets(:other_table) }
    let!(:workspace_association) { workspace.source_datasets << source_dataset }
    subject do
      Events::ImportScheduleDeleted.add(
          :actor => actor,
          :dataset => dataset,
          :source_dataset => source_dataset,
          :workspace => workspace,
          :destination_table => dataset.name
      )
    end

    its(:dataset) { should == dataset }
    its(:targets) { should == {:workspace => workspace, :dataset => dataset, :source_dataset => source_dataset} }
    its(:additional_data) { should == { 'destination_table' => dataset.name } }

    it_creates_activities_for { [actor, workspace, dataset, source_dataset] }
    it_does_not_create_a_global_activity
  end

  describe "FileImportFailed" do
    subject do
      Events::FileImportFailed.add(
          :actor => actor,
          :file_name => 'import.csv',
          :import_type => 'file',
          :destination_table => 'test',
          :workspace => workspace,
          :error_message => 'Flying Monkey Attack',
          :dataset => destination_dataset
      )
    end

    its(:targets) { should == {:workspace => workspace, :dataset => destination_dataset} }
    its(:additional_data) { should == {'file_name' => "import.csv", 'import_type' => "file", 'destination_table' => 'test', 'error_message' => 'Flying Monkey Attack'} }

    it_creates_activities_for { [actor, workspace, destination_dataset] }
    it_does_not_create_a_global_activity
  end

  describe "GnipStreamImportCreated" do
    let(:gnip_data_source) { gnip_data_sources(:default) }
    subject do
      Events::GnipStreamImportCreated.add(
          :dataset => dataset,
          :gnip_data_source => gnip_data_source,
          :workspace => workspace
      )
    end

    its(:dataset) { should == dataset }
    its(:targets) { should == {:workspace => workspace, :dataset => dataset, :gnip_data_source => gnip_data_source} }

    it_creates_activities_for { [workspace, dataset, gnip_data_source] }
    it_does_not_create_a_global_activity
  end

  describe "GnipStreamImportSuccess" do
    let(:gnip_data_source) { gnip_data_sources(:default) }
    subject do
      Events::GnipStreamImportSuccess.add(
          :dataset => dataset,
          :gnip_data_source => gnip_data_source,
          :workspace => workspace
      )
    end

    its(:dataset) { should == dataset }
    its(:targets) { should == {:workspace => workspace, :dataset => dataset, :gnip_data_source => gnip_data_source} }

    it_creates_activities_for { [workspace, dataset, gnip_data_source] }
    it_does_not_create_a_global_activity
  end

  describe "GnipStreamImportFailed" do
    let(:gnip_data_source) { gnip_data_sources(:default) }
    subject do
      Events::GnipStreamImportFailed.add(
          :destination_table => dataset.name,
          :gnip_data_source => gnip_data_source,
          :workspace => workspace,
          :error_message => 'Flying Monkey Attack'
      )
    end

    its(:destination_table) { should == dataset.name }
    its(:targets) { should == {:workspace => workspace, :gnip_data_source => gnip_data_source} }
    its(:error_message) { should == 'Flying Monkey Attack' }

    it_creates_activities_for { [workspace, gnip_data_source] }
    it_does_not_create_a_global_activity
  end

  describe "MembersAdded" do
    subject do
      Events::MembersAdded.add(
          :actor => actor,
          :member => user,
          :workspace => workspace,
          :num_added => 3
      )
    end

    its(:member) { should == user }
    its(:targets) { should == {:member => user, :workspace => workspace} }
    its(:additional_data) { should == {'num_added' => 3} }

    it_creates_activities_for { [actor, workspace] }
    it_does_not_create_a_global_activity
  end

  describe "WorkfileUpgradedVersion" do
    subject do
      Events::WorkfileUpgradedVersion.add(
          :actor => actor,
          :workfile => workfile,
          :workspace => workspace,
          :version_num => 2,
          :commit_message => "a nice commit message",
          :version_id => 10
      )
    end

    its(:workfile) { should == workfile }
    its(:workspace) { should == workspace }

    its(:targets) { should == {:workfile => workfile, :workspace => workspace} }
    its(:additional_data) { should == {'version_num' => 2, 'commit_message' => "a nice commit message", 'version_id' => 10} }

    it_creates_activities_for { [actor, workfile, workspace] }
    it_does_not_create_a_global_activity
  end

  describe "WorkspaceChangeName" do
    subject do
      Events::WorkspaceChangeName.add(
          :actor => actor,
          :workspace => workspace,
          :workspace_old_name => "oldname"
      )
    end

    its(:workspace) { should == workspace }

    its(:targets) { should == {:workspace => workspace} }
    its(:additional_data) { should == {'workspace_old_name' => 'oldname'} }

    it_creates_activities_for { [actor, workspace] }
    it_does_not_create_a_global_activity
  end

  describe "WorkspaceDeleted" do
    subject do
      Events::WorkspaceDeleted.add(
          :actor => actor,
          :workspace => workspace
      )
    end

    context "when workspace is not public " do
      let(:workspace) {workspaces(:private)}

      its(:workspace) { should == workspace }

      its(:targets) { should == {:workspace => workspace} }

      it_creates_activities_for { [actor] }
      it_does_not_create_a_global_activity
    end

    context "when workspace is public" do

      let(:workspace) {workspaces(:public)}

      it_creates_a_global_activity
    end
  end

  describe "TableauWorkbookPublished" do
    subject do
      Events::TableauWorkbookPublished.add(
          :actor => actor,
          :workspace => workspace,
          :dataset => dataset,
          :workbook_name => "testingbook",
          :workbook_url => "test.com/workbook/testingbook",
          :project_url => "test.com/projects/Default"
      )
    end

    its(:workspace) { should == workspace }

    its(:targets) { should == { :workspace => workspace, :dataset => dataset } }
    its(:additional_data) { should == { 'workbook_name' => "testingbook", 'workbook_url' => 'test.com/workbook/testingbook', 'project_url' => 'test.com/projects/Default'} }

    it_creates_activities_for { [actor, workspace, dataset] }
    it_does_not_create_a_global_activity
  end

  describe "TableauWorkfileCreated" do
    let(:workfile) { workfiles(:tableau) }

    subject do
      Events::TableauWorkfileCreated.add(
          :actor => actor,
          :workspace => workspace,
          :dataset => dataset,
          :workfile => workfile,
          :workbook_name => "testingbook"
      )
    end

    its(:workspace) { should == workspace }

    its(:targets) { should == { :workspace => workspace, :dataset => dataset, :workfile => workfile } }
    its(:additional_data) { should == { 'workbook_name' => "testingbook"} }

    it_creates_activities_for { [actor, workspace, dataset, workfile] }
    it_does_not_create_a_global_activity
  end
end
