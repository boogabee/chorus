require 'spec_helper'

describe GpdbDataset do
  let(:gpdb_data_source) { data_sources(:owners) }
  let(:account) { gpdb_data_source.owner_account }
  let(:schema) { schemas(:default) }
  let(:other_schema) { schemas(:other_schema) }
  let(:dataset) { datasets(:table) }
  let(:source_table) { datasets(:source_table) }
  let(:dataset_view) { datasets(:view) }

  describe "#data_source_account_ids" do
    it "returns data source account ids with access to the database" do
      dataset.data_source_account_ids.should == dataset.database.data_source_account_ids
    end
  end

  describe 'execution_location' do
    it "returns the Dataset's parent database" do
      dataset.execution_location.should == dataset.database
    end
  end

  describe "associations" do
    it { should have_many :associated_datasets }
    it { should have_many :bound_workspaces }
    it { should be_associable }
  end

  context ".total_entries" do
    before do
      connection = Object.new
      stub(schema).connect_with(account) { connection }
      stub(connection).datasets_count { 3 }
    end

    it "returns the number of total entries" do
      GpdbDataset.total_entries(account, schema).should == 3
    end
  end

  describe 'importability', :greenplum_integration do
    let(:schema) { GpdbSchema.find_by_name('test_schema') }
    let(:source) { schema.datasets.find_by_name('base_table1') }

    it_behaves_like 'an importable dataset'
  end

  describe "#destroy" do
    let(:dataset) { datasets(:table) }

    before do
      any_instance_of(GreenplumConnection) do |data_source|
        stub(data_source).running? { false }
      end
    end

    it "should not delete the dataset entry" do
      dataset.destroy
      expect {
        dataset.reload
      }.to_not raise_error(Exception)
    end

    it "should update the deleted_at field" do
      dataset.destroy
      dataset.reload.deleted_at.should_not be_nil
    end

    it "destroys dependent tableau_workbook_publications" do
      tableau_publication = tableau_workbook_publications(:default)
      dataset = tableau_publication.dataset

      dataset.destroy
      TableauWorkbookPublication.find_by_id(tableau_publication.id).should be_nil
    end

    it "destroys dependent associated_datasets" do
      associated_dataset = AssociatedDataset.first
      dataset = associated_dataset.dataset

      dataset.destroy
      AssociatedDataset.find_by_id(associated_dataset.id).should be_nil
    end
  end

  describe "in_workspace?" do
    let(:workspace) { workspaces(:public) }
    let(:dataset) { datasets(:source_table) }

    context "when the datset is in the workspace" do
      before do
        dataset.bound_workspaces = []
        dataset.bound_workspaces << workspace
      end
      it "is true" do
        dataset.in_workspace?(workspace).should be_true
      end
    end

    context "when the dataset is not in the workspace" do
      before do
        dataset.bound_workspaces = []
      end

      context "but the dataset is in the sandbox" do
        before do
          workspace.sandbox = dataset.schema
          workspace.save!
        end

        it "is true" do
          dataset.in_workspace?(workspace).should be_true
        end
      end

      context "when the dataset is not in the sandbox" do
        it "is false" do
          dataset.in_workspace?(workspace).should be_false
        end
      end
    end

    context "when the workspace does not have a sandbox" do
      let(:workspace) { workspaces(:no_sandbox) }

      it "returns false" do
        dataset.in_workspace?(workspace).should be_false
      end
    end
  end

  describe 'found_in_workspace_id' do
    context "when the dataset is associated with a workspace" do
      let(:dataset) { datasets(:source_table) }
      let(:workspace) { workspaces(:public) }

      it 'includes the workspace ID' do
        dataset.found_in_workspace_id.should include(workspace.id)
      end
    end

    context "when the dataset is not associated with a workspace" do
      let(:dataset) { datasets(:table) }

      context "but the workspace's sandbox contains the dataset" do
      let(:workspace) do
        workspaces(:public).tap { |ws| ws.sandbox = dataset.schema; ws.save! }
      end

      before do
        dataset.bound_workspaces.should_not include(workspace)
      end

        it "includes that workspace's id" do
          dataset.found_in_workspace_id.should include(workspace.id)
        end

        context "and the workspace does not automatically show sandbox datasets" do
          before do
            workspace.show_sandbox_datasets = false
            workspace.save!
          end

          it "does not include that workspace's id" do
            dataset.found_in_workspace_id.should_not include(workspace.id)
          end
        end
      end
    end
  end
end
