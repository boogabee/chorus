require 'spec_helper'

describe PgDataSource do

  it { should have_many(:databases).class_name('PgDatabase') }
  it { should have_many(:schemas).through(:databases) }
  it { should have_many(:datasets).through(:schemas) }

  describe '#destroy' do
    let(:data_source) { data_sources(:postgres) }

    before do
      any_instance_of(PostgresConnection) { |connection| stub(connection).running? }
    end

    it 'enqueues a destroy_databases job' do
      mock(QC.default_queue).enqueue_if_not_queued('Database.destroy_databases', data_source.id)
      data_source.destroy
    end
  end

  describe '#create_database' do
    let(:connection) { Object.new }
    let(:data_source) { data_sources(:postgres) }
    let(:user) { 'hiya' }
    let(:database_name) { 'things' }

    before do
      stub(data_source).connect_as(user) { connection }
      stub(data_source).refresh_databases { data_source.databases.create(:name => database_name) }
    end

    it 'should create the database' do
      mock(connection).create_database(database_name)
      expect do
        data_source.create_database(database_name, user).name.should == database_name
      end.to change(PgDatabase, :count).by(1)
    end

    context 'when the database is invalid' do
      before do
        any_instance_of(PgDatabase) do |database|
          stub(database).valid? { false }
        end
      end

      it 'should not create a database' do
        dont_allow(connection).create_database.with_any_args
        expect do
          expect do
            data_source.create_database(database_name, user)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end.not_to change(PgDatabase, :count)
      end
    end
  end

  it_should_behave_like :data_source_with_access_control
  it_should_behave_like :data_source_with_db_name_port_validations

  it_behaves_like(:data_source_with_update) do
    let(:data_source) { data_sources(:postgres) }
  end

  it_behaves_like 'a data source with sandboxes' do
    let(:data_source) { FactoryGirl.create :pg_data_source }
    let(:database) { FactoryGirl.create(:pg_database, :data_source => data_source, :name => 'db') }
    let(:schema) { FactoryGirl.create(:pg_schema, :name => 'schema', :database => database) }
  end
end
