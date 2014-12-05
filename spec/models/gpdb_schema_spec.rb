require 'spec_helper'

describe GpdbSchema do
  it_behaves_like 'a subclass of schema' do
    let(:schema) { schemas(:default) }
    let(:table_factory) { :gpdb_table }
    let(:view_factory) { :gpdb_view }
  end

  it_behaves_like 'a sandbox schema' do
    let(:schema) { schemas(:default) }
  end

  describe "associations" do
    it { should belong_to(:scoped_parent) }
    it { should have_many(:datasets) }
    it { should have_many(:imports) }

    describe "#database" do
      let(:schema) {
         GpdbSchema.create!(:name => 'test_schema', :database => databases(:default))
      }

      it "returns the schemas parent" do
        schema.reload.database.should == databases(:default)
      end
    end

    describe 'validations' do
      it 'has a valid factory' do
        FactoryGirl.build(:gpdb_schema).should be_valid
      end

      it { should validate_presence_of(:name) }

      it 'does not allow slashes, ampersands and question marks' do
        ['/', '&', '?'].each do |char|
          new_schema = FactoryGirl.build(:gpdb_schema, :name => "schema#{char}name")
          new_schema.should have_error_on(:name)
        end
      end

      describe 'name uniqueness' do
        let(:existing) { schemas(:default) }

        context 'in the same db' do
          it 'does not allow two databases with the same name' do
            new_schema = FactoryGirl.build(:gpdb_schema,
                                           :name => existing.name,
                                           :database => existing.database)
            new_schema.should have_error_on(:name).with_message(:taken)
          end
        end

        context 'in a different db' do
          it 'allows same names' do
            new_schema = FactoryGirl.build(:gpdb_schema,
                                           :name => existing.name)
            new_schema.should be_valid
          end
        end
      end
    end

    describe "cascading deletes" do
      before do
        any_instance_of(GreenplumConnection) do |data_source|
          stub(data_source).running? { false }
        end
      end
    end
  end

  describe '#accessible_to' do
    let(:gpdb_data_source) { data_sources(:owners) }
    let(:account) { gpdb_data_source.owner_account }
    let(:schema) { schemas(:default) }

    it 'returns true if the user can access the gpdb data source' do
      owner = account.owner
      any_instance_of(GpdbDataSource) do |data_source|
        mock(data_source).accessible_to(owner) { true }
      end

      schema.accessible_to(owner).should be_true
    end
  end

  context "refresh returns the list of schemas", :greenplum_integration do
    let(:account) { GreenplumIntegration.real_account }
    let(:database) { GpdbDatabase.find_by_name(GreenplumIntegration.database_name) }

    it "returns the sorted list of schemas" do
      schemas = GpdbSchema.refresh(account, database)
      schemas.map(&:name).sort.should == schemas.map(&:name).sort
    end
  end

  describe "#connect_with" do
    let(:schema) { schemas(:public) }
    let(:account) { data_source_accounts(:unauthorized) }
    let(:mockConnection) { {} }

    before do
      mock(GreenplumConnection).new(schema.data_source, account, {
          :schema => schema.name,
          :database => schema.database.name,
          :logger => Rails.logger
      }) {
        mockConnection
      }
    end

    it "should create a Greenplum SchemaConnection" do
      schema.connect_with(account)
    end

    it "passes a connected connection a block" do
      stub(mockConnection).with_connection.yields(mockConnection)
      expect {
        schema.connect_with(account) do |connection|
          connection.should == mockConnection
          throw :ran_block
        end
      }.to throw_symbol :ran_block
    end
  end

  describe '#active_tables_and_views' do
    let(:schema) { schemas(:default) }

    it 'does not include chorus views' do
      cv = nil
      expect {
        cv = FactoryGirl.create(:chorus_view, :schema => schema)
      }.not_to change { schema.reload.active_tables_and_views.size }
      schema.active_tables_and_views.should_not include(cv)
    end
  end

  describe "#destroy" do
    let(:schema) { schemas(:default) }

    before do
      any_instance_of(GreenplumConnection) do |connection|
        stub(connection).running? { false }
      end
    end

    it "cancels any running schema imports" do
      unfinished_imports = schema.imports.unfinished
      stub(schema.imports).unfinished { unfinished_imports }
      unfinished_imports.should_not be_empty
      unfinished_imports.each do |import|
        mock(import).cancel(false, "Source/Destination of this import was deleted")
      end
      schema.destroy
    end

    it "cancels any running workspace imports" do
      import = imports(:csv)
      schema = import.workspace.sandbox

      import.success.should be_nil
      schema.destroy
      import.reload.success.should == false
    end
  end

  describe "#class_for_type" do
    let(:schema) { schemas(:default) }
    it "should return GpdbTable and GpdbView correctly" do
      schema.class_for_type('r').should == GpdbTable
      schema.class_for_type('v').should == GpdbView
    end
  end
end
