shared_examples_for 'a subclass of schema' do
  context '.refresh' do
    let(:schema_parent) do
      stub(schema.parent).connect_with(account) { connection }
      schema.parent
    end
    let(:account) { Object.new }
    let(:connection) { Object.new }
    let(:dropped_schema) { schema_parent.schemas.where("id <> #{schema.id} AND name <> 'new_schema'").first! }

    before(:each) do
      stub(Dataset).refresh
      stub(connection).schemas { ['new_schema', schema.name] }
    end

    it 'creates new copies of the schemas in our db' do
      Schema.refresh(account, schema_parent)
      schema_parent.schemas.where(:name => 'new_schema').should exist
    end

    it 'refreshes all Datasets when :refresh_all is true, passing the options to schema refresh_datasets' do
      options = {:dostuff => true, :refresh_all => true}
      mock(Dataset).refresh(account, anything, options).times(2)
      Schema.refresh(account, schema_parent, options)
    end

    it 'does not re-create schemas that already exist in our schema_parent' do
      Schema.refresh(account, schema_parent)
      expect {
        Schema.refresh(account, schema_parent)
      }.not_to change(Schema, :count)
    end

    it 'marks schema as stale if it does not exist' do
      Schema.refresh(account, schema_parent, :mark_stale => true)
      dropped_schema.should be_stale
      dropped_schema.stale_at.should be_within(5.seconds).of(Time.current)
    end

    it 'does not mark schema as stale if flag is not set' do
      Schema.refresh(account, schema_parent)
      dropped_schema.should_not be_stale
    end

    it 'does not update the stale_at time' do
      Timecop.freeze(1.year.ago) do
        dropped_schema.mark_stale!
      end
      Schema.refresh(account, schema_parent, :mark_stale => true)
      dropped_schema.reload.stale_at.should be_within(5.seconds).of(1.year.ago)
    end

    it 'clears stale flag on schema if it is found again' do
      schema.mark_stale!
      Schema.refresh(account, schema_parent)
      schema.reload.should_not be_stale
    end

    context 'when the schema_parent is not available' do
      before do
        stub(connection).schemas { raise DataSourceConnection::Error.new }
      end

      it 'marks all the associated schemas as stale if mark_stale is set' do
        expect {
          Schema.refresh(account, schema_parent, :mark_stale => true)
        }.to raise_error(DataSourceConnection::Error)
        schema.reload.should be_stale
      end

      it 'does not mark the associated schemas as stale if mark_stale is not set' do
        expect {
          Schema.refresh(account, schema_parent)
        }.to raise_error(DataSourceConnection::Error)
        schema.reload.should_not be_stale
      end
    end
  end

  it_should_behave_like 'something that can go stale' do
    let(:model) { schema }
  end

  it_behaves_like 'a soft deletable model' do
    let(:model) { schema }
  end

  describe '#destroy' do
    it 'destroys dependent datasets' do
      datasets = schema.datasets
      datasets.length.should > 0

      expect {
        schema.destroy
      }.to change(schema.datasets, :count).to(0)
    end
  end

  describe 'callbacks' do
    describe 'before_save' do
      describe '#mark_datasets_as_stale' do
        it 'if the schema has become stale, datasets will also be marked as stale' do
          schema.mark_stale!
          dataset = schema.datasets.views_tables.first
          dataset.should be_stale
          dataset.stale_at.should be_within(5.seconds).of(Time.current)
        end
      end
    end
  end

  describe '#active_tables_and_views' do
    it 'includes tables' do
      table = nil
      expect {
        table = FactoryGirl.create(table_factory, :schema => schema)
      }.to change { schema.reload.active_tables_and_views.size }.by(1)
      schema.active_tables_and_views.should include(table)

      expect {
        table.mark_stale!
      }.to change { schema.reload.active_tables_and_views.size }.by(-1)
      schema.active_tables_and_views.should_not include(table)
    end

    it 'includes views' do
      view = nil

      expect {
        view = FactoryGirl.create(view_factory, :schema => schema)
      }.to change { schema.reload.active_tables_and_views.size }.by(1)
      schema.active_tables_and_views.should include(view)

      expect {
        view.mark_stale!
      }.to change { schema.reload.active_tables_and_views.size }.by(-1)
      schema.active_tables_and_views.should_not include(view)
    end
  end
end

shared_examples 'a sandbox schema' do

  describe 'associations' do
    it { should have_many(:workspaces) }
  end

  describe '#destroy' do
    it 'nullifies its sandbox association in workspaces' do
      workspace = FactoryGirl.create(:workspace, :sandbox => schema)

      expect {
        expect {
          schema.destroy
        }.to_not change(Workspace, :count)
      }.to change { workspace.reload.sandbox }.from(schema).to(nil)
    end

    it 'removes any execution schemas from associated workfiles' do
      FactoryGirl.create(:chorus_workfile, :execution_schema => schema)
      workfiles = schema.workfiles_as_execution_location.all
      workfiles.length.should > 0

      schema.destroy
      workfiles.each do |workfile|
        workfile.reload.execution_location_id.should be_nil
      end
    end
  end

  describe '#disk_space_used' do
    let(:account) { data_source_accounts(:unauthorized) }
    let(:connection) { Object.new }
    let(:disk_space_used) { 12345 }

    before do
      stub(schema).connect_with(account) { connection }
      mock(connection).disk_space_used { disk_space_used }
    end

    it 'returns the disk space used by all relations in the schema' do
      schema.disk_space_used(account).should == 12345
    end

    it 'caches the value' do
      schema.disk_space_used(account).should == 12345
      schema.disk_space_used(account).should == 12345
    end

    context 'when we cannot calculate the size' do
      let(:disk_space_used) { raise Exception }

      it 'should return nil' do
        schema.disk_space_used(account).should be_nil
      end

      it 'should cache the value correctly' do
        schema.disk_space_used(account).should be_nil
        schema.disk_space_used(account).should be_nil
      end
    end
  end

  describe '#stored_functions' do
    let(:account) { schema.database.data_source.owner_account }
    let(:connection) { Object.new }

    before do
      stub(schema).connect_with(account) { connection }
      stub(connection).functions do
        [
            {:oid => 62792, :proname => 'funky_town', :lanname => 'sql', :rettype => 'text', :proargnames => ['i'], :argtypes => 'int4', :prosrc => " SELECT CAST($1 AS text) || ' is text' ", :description => 'comment on funky_town'},
            {:oid => 62793, :proname => 'towny_funk', :lanname => 'sql', :rettype => 'record', :proargnames => ['i', 'foo', 'bar'], :argtypes => 'int4', :prosrc => " SELECT $1, CAST($1 AS text) || ' is text' ", :description => nil},
            {:oid => 63121, :proname => 'multi_arg_function', :lanname => 'sql', :rettype => 'int4', :proargnames => ['i', 'j', 'k'], :argtypes => 'float8', :prosrc => 'select 1', :description => 'comment on multi_arg'},
            {:oid => 63121, :proname => 'multi_arg_function', :lanname => 'sql', :rettype => 'int4', :proargnames => ['i', 'j', 'k'], :argtypes => 'varchar', :prosrc => 'select 1', :description => 'comment on multi_arg'},
            {:oid => 63121, :proname => 'multi_arg_function', :lanname => 'sql', :rettype => 'int4', :proargnames => ['i', 'j', 'k'], :argtypes => 'int4', :prosrc => 'select 1', :description => 'comment on multi_arg'}
        ]
      end
    end

    it 'returns the SchemaFunctions' do
      functions = schema.stored_functions(account)

      functions.count.should == 3

      last_function = functions.last
      last_function.should be_a SchemaFunction
      last_function.schema_name.should == schema.name
      last_function.function_name.should == 'multi_arg_function'
      last_function.language.should == 'sql'
      last_function.return_type.should == 'int4'
      last_function.arg_names.should == ['i', 'j', 'k']
      last_function.arg_types.should == ['float8', 'varchar', 'int4']
      last_function.definition.should == 'select 1'
      last_function.description.should == 'comment on multi_arg'
    end
  end
end
