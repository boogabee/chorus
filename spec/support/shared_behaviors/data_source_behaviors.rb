shared_examples_for :data_source_integration do
  describe "#valid_db_credentials?" do
    it "returns true when the credentials are valid" do
      data_source.valid_db_credentials?(account).should be_true
    end

    it "returns false when the credentials are invalid" do
      account.db_username = 'awesome_hat'
      data_source.valid_db_credentials?(account).should be_false
    end

    it "raises a DataSourceConnection::Error when other errors occur" do
      data_source.host = 'something_fake'
      expect {
        data_source.valid_db_credentials?(account)
      }.to raise_error(DataSourceConnection::Error)
    end
  end
end

shared_examples_for :data_source_with_access_control do
  let(:factory_name) { described_class.name.underscore.to_sym }

  describe "access control" do
    let(:user) { users(:owner) }

    before do
      @data_source_owned = FactoryGirl.create factory_name, :owner => user
      @data_source_shared = FactoryGirl.create factory_name, :shared => true
      @data_source_with_membership = FactoryGirl.create factory_name
      @data_source_forbidden = FactoryGirl.create factory_name

      @membership_account = FactoryGirl.build :data_source_account, :owner => user, :data_source => @data_source_with_membership
      @membership_account.save(:validate => false)
    end

    describe '.accessible_to' do
      it "returns owned data sources" do
        described_class.accessible_to(user).should include @data_source_owned
      end

      it "returns shared data sources" do
        described_class.accessible_to(user).should include @data_source_shared
      end

      it "returns data source data sources to which user has membership" do
        described_class.accessible_to(user).should include @data_source_with_membership
      end

      it "does not return data sources the user has no access to" do
        described_class.accessible_to(user).should_not include(@data_source_forbidden)
      end
    end

    describe '#accessible_to' do
      it 'returns true if the data_source is shared' do
        @data_source_shared.accessible_to(user).should be_true
      end

      it 'returns true if the data_source is owned by the user' do
        @data_source_owned.accessible_to(user).should be_true
      end

      it 'returns true if the user has an data_source account' do
        @data_source_with_membership.accessible_to(user).should be_true
      end

      it 'returns false otherwise' do
        @data_source_forbidden.accessible_to(user).should be_false
      end
    end
  end

  describe ".unshared" do
    it "returns unshared gpdb data sources" do
      unshared_data_sources = described_class.unshared
      unshared_data_sources.length.should > 0
      unshared_data_sources.each { |i| i.should_not be_shared }
    end
  end

  describe '#license_type' do
    its(:license_type) { should == subject.type }
  end

  describe 'validations' do
    it { should validate_presence_of :name  }

    it { should validate_with DataSourceNameValidator }
    it { should validate_with DataSourceTypeValidator }

    it_should_behave_like 'a model with name validations'

    context "when host, port, or db_name change" do
      let(:data_source_account) { FactoryGirl.build :data_source_account }
      let(:data_source) { FactoryGirl.build factory_name, :owner_account => data_source_account }

      before do
        data_source.save!(:validate => false)
        stub(data_source).owner_account { data_source_account }
        mock(data_source_account).valid? { true }
      end

      it "validates the account when host changes" do
        data_source.host = 'something_new'
        data_source.valid?.should be_true
      end

      it "validates the account when port changes" do
        data_source.port = '5413'
        data_source.valid?.should be_true
      end

      it "validates the account when db_name changes" do
        data_source.db_name = 'something_new'
        data_source.valid?.should be_true
      end

      it "pulls associated error messages onto the data_source" do
        stub(data_source).valid_db_credentials? { false }
        data_source.db_name = 'something_new'
        data_source.valid?.should be_true
        data_source.errors.values.should =~ data_source.owner_account.errors.values
      end
    end

    describe "when name changes" do
      let!(:data_source) { FactoryGirl.create factory_name }
      it "it does not validate the account" do
        any_instance_of(DataSourceAccount) do |account|
          dont_allow(account).valid?
        end
        data_source.name = 'purple_bandana'
        data_source.valid?.should be_true
      end
    end
  end

  describe "associations" do
    it { should belong_to :owner }
    it { should have_many :accounts }
    it { should have_one :owner_account }
    it { should have_many :activities }
    it { should have_many :events }
  end

  describe 'activity creation' do
    let(:user) { users(:admin) }
    let :valid_input_attributes do
      {
          :name => "create_spec_name",
          :port => 12345,
          :host => "server.emc.com",
          :db_name => "postgres",
          :description => "old description",
          :db_username => "bob",
          :db_password => "secret"
      }
    end

    it "makes a DataSourceCreated event" do
      set_current_user(user)
      data_source = nil
      expect {
        data_source = FactoryGirl.create(factory_name, :owner => user)
      }.to change(Events::DataSourceCreated, :count).by(1)
      event = Events::DataSourceCreated.last
      event.data_source.should == data_source
      event.actor.should == user
    end
  end

  describe "#destroy" do
    let(:data_source) { FactoryGirl.create factory_name }

    it "should not delete the database entry" do
      data_source.destroy
      expect {
        data_source.reload
      }.to_not raise_error(Exception)
    end

    it "should update the deleted_at field" do
      data_source.destroy
      data_source.reload.deleted_at.should_not be_nil
    end

    it "destroys dependent data_source accounts" do
      data_source_accounts = data_source.accounts
      data_source_accounts.length.should > 0

      data_source.destroy
      data_source_accounts.each do |account|
        DataSourceAccount.find_by_id(account.id).should be_nil
      end
    end
  end

  describe '#connect_as_owner' do
    let(:data_source) { FactoryGirl.build factory_name }

    before do
      mock(data_source).connect_with(data_source.owner_account)
    end

    it 'connects with the owners account' do
      data_source.connect_as_owner
    end
  end

  describe "#connect_with" do
    let(:data_source) { FactoryGirl.build factory_name }
    let(:account) { Object.new }
    let(:fake_connection_class) { Struct.new(:foo, :bar, :baz) }

    before do
      mock(data_source).connection_class { fake_connection_class }
    end

    it "returns an data source of the data source's connection_class" do
      data_source.connect_with(account).should be_an_instance_of(fake_connection_class)
    end
  end

  describe '#attempt_connection' do
    let(:data_source) { FactoryGirl.build factory_name }
    let(:user) { users(:default) }

    it 'should try to connect as the given user' do
      mock(data_source).connect_as(user) do |connection|
        mock(connection).with_connection
      end

      data_source.attempt_connection(user)
    end
  end
end

shared_examples_for :data_source_with_db_name_port_validations do
  let(:factory_name) { described_class.name.underscore.to_sym }

  it { should validate_presence_of :db_name }

  describe 'port' do
    context 'when port is not a number' do
      it 'fails validation' do
        FactoryGirl.build(factory_name, :port => '1aaa1').should_not be_valid
      end
    end

    context 'when port is number' do
      it 'validates' do
        FactoryGirl.build(factory_name, :port => '1111').should be_valid
      end
    end

    context 'when host is set but not port' do
      it 'fails validation' do
        FactoryGirl.build(factory_name, :host => '1111', :port => "").should_not be_valid
      end
    end
  end
end


shared_examples_for :data_source_with_update do
  before do
    any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? { true } }
  end

  it "does not allow you to update the shared attribute" do
    data_source.shared = true
    data_source.save!
    data_source.update_attributes!(:shared => false)
    data_source.shared.should be_true
  end

  it "generates a DataSourceChangedName event when the name is being changed" do
    set_current_user(data_source.owner)
    old_name = data_source.name
    expect {
      data_source.update_attributes(:name => 'something_else')
    }.to change(Events::DataSourceChangedName, :count).by(1)
    event = Events::DataSourceChangedName.find_last_by_actor_id(data_source.owner)
    event.data_source.should == data_source
    event.old_name.should == old_name
    event.new_name.should == 'something_else'
  end

  it "does not generate an event when the name is not being changed" do
    expect {
      data_source.update_attributes!(:description => 'hi!')
    }.to_not change(Events::DataSourceChangedName, :count)
  end
end

shared_examples_for 'a data source with sandboxes' do
  let!(:ws_sandbox) { FactoryGirl.create(:workspace, :name => 'Z_workspace', :sandbox => schema) }
  let!(:public_ws_sandbox) { FactoryGirl.create(:workspace, :name => 'a_workspace', :sandbox => schema, :public => false) }
  let!(:ws_without_sandbox) { FactoryGirl.create(:workspace, :name => 'ws_3') }

  it "returns the workspaces that use this data_source's schema as sandbox" do
    workspaces = data_source.used_by_workspaces(users(:admin))
    workspaces.count.should == 2
    workspaces.should include(ws_sandbox)
    workspaces.should include(public_ws_sandbox)
    workspaces.should_not include(ws_without_sandbox)
  end

  it 'only returns workspaces visible to the user' do
    workspaces = data_source.used_by_workspaces(users(:not_a_member))
    workspaces.count.should == 1
    workspaces.should include(ws_sandbox)
  end

  it 'sorts the workspaces alphabetically (case insensitive)' do
    workspaces = data_source.used_by_workspaces(users(:admin))
    workspaces.map(&:name).should == [public_ws_sandbox, ws_sandbox].map(&:name).sort_by { |name| name.downcase }
  end
end
