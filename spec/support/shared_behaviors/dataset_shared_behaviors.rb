shared_examples 'a dataset table' do
  let(:account) { table.data_source.owner_account }
  let(:user) { table.data_source.owner }
  let(:connection) { Object.new }

  before do
    stub(table.schema).connect_with(account) { connection }
    stub(table.schema.parent).connect_with(account) { connection }
  end

  describe '#analyze' do
    it 'calls out to the connection' do
      mock(connection).analyze_table(table.name)
      table.analyze(account)
    end
  end

  describe '#verify_in_source' do
    it 'is true if the table & schema exist' do
      stub(connection).schema_exists?(table.schema.name) { true }
      stub(connection).table_exists?(table.name) { true }
      table.verify_in_source(user).should be_true
    end

    it 'is false if the table or schema do not exist' do
      stub(connection).schema_exists?(table.schema.name) { true }
      stub(connection).table_exists?(table.name) { false }
      table.verify_in_source(user).should be_false

      stub(connection).schema_exists?(table.schema.name) { false }
      stub(connection).table_exists?(table.name) { true }
      table.verify_in_source(user).should be_false

      stub(connection).schema_exists?(table.schema.name) { false }
      stub(connection).table_exists?(table.name) { false }
      table.verify_in_source(user).should be_false
    end
  end
end

shared_examples 'a dataset view' do
  let(:account) { view.data_source.owner_account }
  let(:user) { view.data_source.owner }
  let(:connection) { Object.new }

  before do
    stub(view.schema).connect_with(account) { connection }
    stub(view.schema.parent).connect_with(account) { connection }
  end

  describe '#verify_in_source' do
    it 'is true if the view & schema exist' do
      stub(connection).schema_exists?(view.schema.name) { true }
      stub(connection).view_exists?(view.name) { true }
      view.verify_in_source(user).should be_true
    end

    it 'is false if the view or schema do not exist' do
      stub(connection).schema_exists?(view.schema.name) { true }
      stub(connection).view_exists?(view.name) { false }
      view.verify_in_source(user).should be_false

      stub(connection).schema_exists?(view.schema.name) { false }
      stub(connection).view_exists?(view.name) { true }
      view.verify_in_source(user).should be_false

      stub(connection).schema_exists?(view.schema.name) { false }
      stub(connection).view_exists?(view.name) { false }
      view.verify_in_source(user).should be_false
    end
  end
end
