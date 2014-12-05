require 'spec_helper'

describe DataSourceAccount do
  it "should allow mass-assignment of username and password" do
    DataSourceAccount.new(:db_username => 'aname').db_username.should == 'aname'
    DataSourceAccount.new(:db_password => 'apass').db_password.should == 'apass'
  end

  describe "validations" do
    let(:gpdb_data_source) { FactoryGirl.build(:gpdb_data_source) }
    let(:account) { data_sources(:default).accounts.first }

    it { should validate_presence_of :db_username }
    it { should validate_presence_of :db_password }

    it "validates the uniqueness of owner_id and data_source_id" do
      data_source = account.data_source
      stub(data_source).valid_db_credentials?(anything) { true }
      new_account = data_source.accounts.build(:owner => account.owner)
      new_account.should have_error_on(:owner_id).with_message(:taken)
    end

    describe "credentials_are_valid" do
      it "validates the credentials are valid" do
        stub(account.data_source).valid_db_credentials?(account) { false }
        account.should have_error_on(:base).with_message(:INVALID_PASSWORD)
      end

      context "when the account is flagged as invalid_credentials" do
        before do
          account.invalid_credentials!
        end

        context "and the credentials are now valid" do
          before do
            stub(account.data_source).valid_db_credentials?(account) { true }
          end

          it "clears the invalid_credentials flag" do
            account.valid?
            account.invalid_credentials.should be_false
          end
        end

        context "and the credentials are still invalid" do
          before do
            any_instance_of(PostgresLikeConnection::DatabaseError) do |exception|
              stub(exception).error_type { :INVALID_PASSWORD }
            end
            stub(Sequel).connect { raise Sequel::DatabaseError }
          end

          it "does not clear the invalid_credentials flag" do
            account.valid?
            account.reload.invalid_credentials.should be_true
          end

          it "does not persist the bad credentials" do
            account.db_username = 'somethingelse'
            account.valid?
            account.reload.db_username.should_not == 'somethingelse'
          end
        end
      end

      context "when the account is not flagged as invalid_credentials" do
        context "and the new credentials are invalid" do
          before do
            any_instance_of(PostgresLikeConnection::DatabaseError) do |exception|
              stub(exception).error_type { :INVALID_PASSWORD }
            end
            stub(Sequel).connect { raise Sequel::DatabaseError }
          end

          it "does not set the invalid_credentials flag" do
            account.valid?
            account.invalid_credentials.should be_false
          end
        end
      end
    end
  end

  describe "associations" do
    it { should belong_to :owner }
    it { should validate_presence_of :owner }

    it { should belong_to :data_source }
    it { should validate_presence_of :data_source }
  end

  describe "password encryption in the rails database" do
    let(:owner) { users(:admin) }
    let(:data_source) { data_sources(:default) }
    let(:password) { "apass" }
    let(:data_source_account) do
      account = data_source.account_for_user(owner)
      stub(account.data_source).valid_db_credentials?(anything) { true }
      account.update_attributes!(:db_password => password, :db_username => 'aname')
      account
    end

    it "stores db_password as encrypted_db_password using the attr_encrypted gem" do
      ActiveRecord::Base.connection.select_values("select encrypted_db_password
                                                  from data_source_accounts where id = #{data_source_account.id}") do |db_password|
        db_password.should_not be_nil
        db_password.should_not == password
      end
    end
  end

  describe "automatic reindexing" do
    let(:data_source) { data_sources(:owners) }
    let(:user) { users(:not_a_member) }

    before do
      stub(Sunspot).index.with_any_args
      any_instance_of(DataSource) { |ds| stub(ds).valid_db_credentials? { true } }
    end

    context "creating a new account" do
      it "should reindex" do
        mock(data_source).refresh_databases_later
        FactoryGirl.create(:data_source_account, :owner => user, :data_source => data_source)
      end
    end

    context "deleting an account" do
      let(:user) { users(:the_collaborator) }
      let(:account) { data_source.account_for_user(user) }
      it "should reindex" do
        mock(account.data_source).refresh_databases_later
        account.destroy
      end
    end

    context "updating an account" do
      let(:user) { users(:the_collaborator) }
      let(:account) { data_source.account_for_user(user) }

      it "should reindex" do
        mock(account.data_source).refresh_databases_later
        account.update_attributes(:db_username => "baz")
      end
    end
  end

  describe "invalid_credentials!" do
    let(:account) { data_source_accounts(:shared_data_source_account) }
    it "flags the model as invalid and saves it" do
      account.invalid_credentials.should be_false
      account.invalid_credentials!
      account.reload
      account.invalid_credentials.should be_true
    end

    it "does not validate the credentials" do
      dont_allow(account).credentials_are_valid
      account.invalid_credentials!
    end

    it "creates a notification" do
      expect {
        account.invalid_credentials!
      }.to change(account.owner.notifications, :count).by(1)
      notification = account.owner.notifications.last
      event = notification.event
      event.should be_a Events::CredentialsInvalid
      event.data_source.should == account.data_source
      event.actor.should == account.owner
    end

    context "when the record has already been flagged as invalid" do
      before do
        account
        already_locked_account = DataSourceAccount.find(account.id)
        already_locked_account.invalid_credentials!
        account.invalid_credentials.should be_false
      end

      it "does not create a new notification" do
        expect {
          account.invalid_credentials!
        }.to_not change(account.owner.notifications, :count)
      end
    end
  end
end
