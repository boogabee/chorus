require "spec_helper"

describe RelationalDataset do
  describe "search fields" do
    let(:dataset) { datasets(:searchquery_table) }

    it "indexes text fields" do
      RelationalDataset.should have_searchable_field :name
      RelationalDataset.should have_searchable_field :table_description
      RelationalDataset.should have_searchable_field :database_name
      RelationalDataset.should have_searchable_field :schema_name
      RelationalDataset.should have_searchable_field :column_name
      RelationalDataset.should have_searchable_field :column_description
    end

    it "returns the schema name for schema_name" do
      dataset.schema_name.should == dataset.schema.name
    end

    it "returns the database name for database_name" do
      dataset.database_name.should == dataset.schema.database.name
    end

    it "un-indexes the dataset when it becomes stale" do
      mock(dataset).solr_remove_from_index
      dataset.mark_stale!
    end

    it "re-indexes the dataset when it becomes un stale" do
      dataset.mark_stale!
      mock(dataset).solr_index
      dataset.stale_at = nil
      dataset.save!
    end

    describe "workspace_ids" do
      let(:workspace) { workspaces(:search_public) }
      let(:chorus_view) { datasets(:searchquery_chorus_view) }

      it "includes the id of all associated workspaces" do
        chorus_view.found_in_workspace_id.should include(workspace.id)
      end

      it "includes the id of all workspaces that include the dataset through a sandbox" do
        dataset.found_in_workspace_id.should include(workspace.id)
      end
    end
  end
end