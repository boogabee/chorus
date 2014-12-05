shared_examples 'a well-behaved database' do

  describe 'callbacks' do
    describe 'before_save' do
      describe '#mark_schemas_as_stale' do
        it 'if the database has become stale, schemas will also be marked as stale' do
          database.mark_stale!
          schema = database.schemas.first
          schema.should be_stale
          schema.stale_at.should be_within(5.seconds).of(Time.current)
        end
      end
    end
  end

  describe '#connect_with' do
    let(:data_source) { database.data_source }
    let(:account) { data_source_accounts(:unauthorized) }
    let(:connection_class) { data_source.send(:connection_class) }

    it 'should return the appropriate connection' do
      mock(connection_class).new(data_source, account, {
          :database => database.name,
          :logger => Rails.logger
      }) { 'this is my connection' }
      database.connect_with(account).should == 'this is my connection'
    end
  end

  describe '#destroy' do
    before do
      any_instance_of(DataSourceConnection) do |data_source|
        stub(data_source).running? { false }
      end
    end

    it 'destroys dependent schemas' do
      schemas = database.schemas
      schemas.length.should > 0

      database.destroy
      schemas.each do |schema|
        Schema.find_by_id(schema.id).should be_nil
      end
    end

    it 'does not destroy data source accounts (but secretly deletes the join model)' do
      database.data_source_accounts << database.data_source.accounts.first
      data_source_accounts = database.reload.data_source_accounts

      data_source_accounts.length.should > 0

      database.destroy
      data_source_accounts.each do |account|
        DataSourceAccount.find_by_id(account.id).should_not be_nil
      end
    end

    let(:workfile) { workfiles(:alpine_flow) }

    it 'removes itself from the execution location field of any workfiles it owns' do
      workfile.workfile_execution_locations.create(execution_location: database)
      workfiles = database.workfile_execution_locations.all
      workfiles.length.should > 0

      # execution_location is polymorphic, so we want to make sure that only the workfiles associated with
      # GpdbDatabase X get nullified, not the ones with GpdbSchema X or HdfsDataSource X
      hdfs_data_source = HdfsDataSource.find database.id
      hdfs_data_source.should_not be_nil
      hdfs_data_source.workfile_execution_locations.create!(:workfile => workfiles.first)
      hdfs_data_source.workfile_execution_locations.length.should > 0

      expect {
        database.destroy
      }.to change { WorkfileExecutionLocation.where(execution_location_id: database.id, execution_location_type: %w(Database GpdbDatabase PgDatabase)).count }.from(workfiles.length).to(0)

      hdfs_data_source.workfile_execution_locations.length.should > 0
    end
  end

  describe 'destroy_databases' do
    it 'destroys databases for given data source id' do
      data_source = database.data_source
      databases = data_source.databases
      databases.should_not be_empty
      Database.destroy_databases(data_source.id)
      databases.reload.should be_empty
    end
  end

  describe '#refresh' do
    let(:data_source) { FactoryGirl.build_stubbed(database.data_source.type.underscore.to_sym) }
    let(:account) { FactoryGirl.build_stubbed(:data_source_account, :data_source => data_source) }
    let(:db_names) { %w(db_a db_B db_C db_d) }
    let(:connection) { Object.new }

    before(:each) do
      stub(data_source).connect_with(account) { connection }
      stub(connection).databases { db_names }
    end

    it 'creates new copies of the databases in our db' do
      Database.refresh(account)

      databases = data_source.databases

      databases.length.should == 4
      databases.map { |db| db.name }.should =~ db_names
      databases.map { |db| db.data_source_id }.uniq.should == [data_source.id]
    end

    it 'returns a list of Database objects' do
      results = Database.refresh(account)

      db_objects = []
      db_names.each do |name|
        db_objects << data_source.databases.find_by_name(name)
      end

      results.should match_array(db_objects)
    end

    it 'does not re-create databases that already exist in our database' do
      Database.refresh(account)
      expect { Database.refresh(account) }.not_to change(Database, :count)
    end

    context 'when database objects are stale' do
      before do
        Database.all.each { |database|
          database.mark_stale!
        }
      end

      it 'marks them as non-stale' do
        Database.refresh(account)
        account.data_source.databases.each { |database|
          database.reload.should_not be_stale
        }
      end
    end
  end
end

shared_examples 'an index-able database' do
  describe 'reindex_datasets' do
    it 'calls solr_index on all datasets' do
      database.datasets.each do |dataset|
        mock(Sunspot).index(dataset)
      end
      Database.reindex_datasets(database.id)
    end

    it 'does not call solr_index on stale datasets' do
      dataset = database.datasets.first
      dataset.mark_stale!
      stub(Sunspot).index(anything)
      dont_allow(Sunspot).index(dataset)
      Database.reindex_datasets(database.id)
    end

    it 'does a solr commit' do
      mock(Sunspot).commit
      Database.reindex_datasets(database.id)
    end

    it 'continues if exceptions are raised' do
      database.datasets.each do |dataset|
        mock(Sunspot).index(dataset) { raise 'error!' }
      end
      mock(Sunspot).commit
      Database.reindex_datasets(database.id)
    end
  end
end
