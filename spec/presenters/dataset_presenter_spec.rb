require 'spec_helper'

describe DatasetPresenter, :type => :view do
  class WithTableauPresenter < DatasetPresenter
    def has_tableau_workbooks?
      true
    end
  end

  before do
    set_current_user(user)
  end

  it_behaves_like 'dataset presenter', :gpdb_table
  it_behaves_like 'dataset presenter with workspace', :gpdb_table

  let(:user) { users(:default) }
  let(:workspace) { FactoryGirl.create :workspace }
  let(:succinct) { false }
  let(:presenter) { WithTableauPresenter.new(dataset, view, {:workspace => workspace, :activity_stream => activity_stream, :succinct => succinct}) }
  let(:activity_stream) { nil }
  let(:hash) { presenter.to_hash }

  describe '.associated_workspaces_hash' do
    let(:dataset) { FactoryGirl.create :gpdb_table }
    let!(:association) { FactoryGirl.create(:associated_dataset, :dataset => dataset, :workspace => workspace) }

    it 'includes associated workspaces' do
      hash[:associated_workspaces][0][:id].should == workspace.id
      hash[:associated_workspaces][0][:name].should == workspace.name
    end

    context 'when rendering an activity stream' do
      let(:activity_stream) { true }

      it 'does not render any associated workspaces' do
        hash[:associated_workspaces].should be_empty
      end
    end
  end

  describe '.tableau_hash' do
    let(:dataset) { datasets(:chorus_view) }
    let(:workbook) { tableau_workbook_publications(:default) }

    it 'includes associated tableau publications' do
      hash[:tableau_workbooks][0][:id].should == workbook.id
      hash[:tableau_workbooks][0][:name].should == workbook.name
      hash[:tableau_workbooks][0][:url].should == workbook.workbook_url
    end

    context "when the presenter doesn't support tableau workbooks" do
      let(:presenter) { DatasetPresenter.new(dataset, view, {:workspace => workspace, :activity_stream => activity_stream}) }

      it 'should not include the tableau workbooks key' do
        hash.should_not have_key(:tableau_workbooks)
      end
    end
  end

  describe 'credentials_hash' do
    context 'for a chorus view' do
      let(:dataset) { workspace.chorus_views.build }

      it 'uses calculated accessible_to' do
        mock(dataset).accessible_to(user) { 'something' }
        hash[:has_credentials].should == 'something'
      end
    end

    context 'for a source dataset' do
      let(:dataset) { datasets(:table) }

      it 'uses calculated accessible_to' do
        stub(presenter).sandbox_table? { false }
        mock(dataset).accessible_to(user) { 'something' }
        hash[:has_credentials].should == 'something'
      end
    end

    context 'for a sandbox dataset' do
      let(:dataset) { datasets(:table) }

      it 'always returns true' do
        stub(presenter).sandbox_table? { true }
        dont_allow(dataset).accessible_to
        hash[:has_credentials].should == true
      end
    end
  end

  describe '#to_hash' do
    context 'when rendering an activity stream' do
      let(:workspace) { FactoryGirl.create :workspace }
      let(:dataset) { FactoryGirl.create :gpdb_table, :schema => schema }
      let(:schema) { FactoryGirl.create :gpdb_schema }
      let(:activity_stream) { true }
      let(:succinct) { true }

      it 'renders no tags, workbooks, credentials' do
        [:tags, :tableau_workbooks, :has_credentials].each do |key|
          hash.should_not have_key(key)
        end
      end

      it 'renders defaults for other keys' do
        hash[:associated_workspaces].should == []
      end

      it 'renders schemas succinctly' do
        hash[:schema].should_not have_key(:has_credentials)
      end

      it 'renders is_deleted' do
        hash.should have_key(:is_deleted)
      end
    end

    context 'for a sandbox table' do
      let(:workspace) { FactoryGirl.create :workspace }
      let(:dataset) { FactoryGirl.create :gpdb_table, :schema => schema }
      let(:schema) { FactoryGirl.create :gpdb_schema }

      before do
        workspace.sandbox_id = schema.id
      end

      it 'has the correct type' do
        hash[:entity_subtype].should == 'SANDBOX_TABLE'
      end

      it 'includes comments fields' do
        hash[:recent_comments].should == []
        hash[:comment_count].should == 0
      end

      it 'includes is_deleted field' do
        hash.should have_key(:is_deleted)
      end

      context 'when the table has tags' do
        let(:dataset) { datasets(:tagged) }

        it 'includes tags' do
          hash[:tags].count.should be > 0
          hash[:tags].should == Presenter.present(dataset.tags, @view)
        end
      end

      context 'when it has comments' do
        let!(:dataset_note) { Events::NoteOnDataset.create!({:note_target => dataset, :body => 'Note on dataset'}, :as => :create) }

        it 'presents the most recent note' do
          hash[:recent_comments].count.should == 1
          hash[:recent_comments][0][:body].should == 'Note on dataset'
        end

        it 'presents the number of comments/notes' do
          hash[:comment_count].should == 1
        end
      end
    end

    context 'for a source table' do
      let(:workspace) { FactoryGirl.create :workspace, :sandbox => schema2 }
      let(:dataset) { FactoryGirl.create :gpdb_table, :schema => schema }
      let(:schema) { FactoryGirl.create :gpdb_schema }
      let(:schema2) { FactoryGirl.create :gpdb_schema }
      let(:association) { FactoryGirl.create(:associated_dataset, :dataset => dataset, :workspace => workspace) }

      it 'has the correct type' do
        hash[:entity_subtype].should == 'SOURCE_TABLE'
      end
    end

    context 'when dataset and schema are soft deleted' do
      let(:workspace) { FactoryGirl.create :workspace, :sandbox => schema }
      let(:schema) { FactoryGirl.create :gpdb_schema }
      let!(:dataset) { FactoryGirl.create :gpdb_table, :schema => schema }
      let(:association) { FactoryGirl.create(:associated_dataset, :dataset => dataset, :workspace => workspace) }
      let(:activity_stream) { true }

      before do
        schema.destroy
        dataset.reload
      end

      it 'presents the schema json' do
        hash.should have_key(:schema)
        hash[:schema][:name].should == schema.name
      end
    end

    context 'when succinct is true' do
      let(:schema) { FactoryGirl.create :gpdb_schema }
      let(:dataset) { FactoryGirl.create :gpdb_table, :schema => schema }
      let(:succinct) { true }

      it 'has the correct keys' do
        hash.keys.should =~ [:id, :object_name, :schema, :associated_workspaces, :entity_subtype, :entity_type, :stale, :is_deleted]
      end

      it 'presents the schema' do
        hash[:schema][:name].should == schema.name
        hash[:schema][:id].should == schema.id
      end
    end
  end

  describe 'complete_json?' do
    let(:dataset) { datasets(:table) }

    context 'when rendering activities' do
      let(:activity_stream) { true }

      it 'is false' do
        presenter.complete_json?.should be_false
      end
    end

    context 'when not rendering activities' do
      let(:activity_stream) { nil }
      it 'is true' do
        presenter.complete_json?.should be_true
      end
    end

    context 'when succinct is true' do
      let(:succinct) { true }

      it 'is false' do
        presenter.complete_json?.should be_false
      end
    end
  end
end
