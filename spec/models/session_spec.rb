require 'spec_helper'

describe Session do
  describe "create" do
    it "sets session_id" do
      user = users(:default)
      session = Session.create!(:username => user.username, :password => FixtureBuilder.password)
      session.session_id.should match /\S{20}/
    end
  end

  describe "validations" do
    it "is invalid if the username is missing" do
      session = Session.new(:username => nil, :password => 'a_password')
      session.should have_error_on(:username).with_message(:blank)
    end

    it "is invalid if the password is missing" do
      session = Session.new(:username => 'a_username', :password => nil)
      session.should have_error_on(:password).with_message(:blank)
    end

    it "is invalid if the credentials are invalid" do
      stub(User).authenticate('a_username', 'a_password') { nil }
      session = Session.new(:username => 'a_username', :password => 'a_password')
      session.should have_error_on(:username_or_password).with_message(:invalid)
    end

    it "is valid if the credentials correct" do
      user = users(:default)
      session = Session.new(:username => user.username, :password => FixtureBuilder.password)
      session.should be_valid
    end

    context "when the LDAP switch is configured" do
      it "uses the LdapClient authentication" do
        user = users(:default)
        stub(LdapClient).enabled? { true }
        stub(LdapClient).authenticate(user.username, 'a_password') { true }

        session = Session.new(:username => user.username, :password => 'a_password')
        session.should be_valid
        session.user.should == user
      end

      it "denies access with wrong LDAP credentials" do
        user = users(:default)
        stub(LdapClient).enabled? { true }
        stub(LdapClient).authenticate(user.username, 'a_password') { false }

        session = Session.new(:username => user.username, :password => 'a_password')
        session.should have_error_on(:username_or_password).with_message(:invalid)
      end

      context "admin logging in" do
        let(:user) { users(:admin) }
        before do
          user.update_attributes!(:username => 'chorusadmin')
        end

        it "authenticates the edcadmin user with the in-database credentials" do
          stub(LdapClient).enabled? { true }
          dont_allow(LdapClient).authenticate

          session = Session.new(:username => user.username, :password => FixtureBuilder.password)
          session.should be_valid
          session.user.should == user
        end

        it "authenticates the edcadmin user with invalid in-database credentials" do
          stub(LdapClient).enabled? { true }
          dont_allow(LdapClient).authenticate

          session = Session.new(:username => user.username, :password => 'wrongpassword')
          session.should have_error_on(:username_or_password).with_message(:invalid)
        end
      end
    end    
  end

  describe "expired?" do
    it "is false when updated_at is less than session timeout minutes ago" do
      stub(ChorusConfig.instance).[]('session_timeout_minutes') { 20 }
      session = Session.new
      session.updated_at = Time.now
      session.should_not be_expired
    end

    it "is true when updated_at is more than session timeout minutes ago" do
      stub(ChorusConfig.instance).[]('session_timeout_minutes') { 20 }
      session = Session.new
      session.updated_at = 21.minutes.ago
      session.should be_expired
    end
  end

  describe "update_expiration!" do
    let(:session) do
      s = Session.new
      s.save(:validate => false)
      s
    end

    before do
      session.updated_at = last_update_time
      session.record_timestamps = false
      session.save(:validate => false)
      session.record_timestamps = true
    end

    context "when updated_at is more than 5 minutes old" do
      let(:last_update_time) { 6.minutes.ago }

      it "resets updated_at" do
        session.update_expiration!
        session.reload.updated_at.should be_within(5.seconds).of(Time.current)
      end
    end

    context "when updated_at is less than 5 minutes old" do
      let(:last_update_time) { 4.minutes.ago }

      it "resets updated_at" do
        session.update_expiration!
        session.reload.updated_at.should_not be_within(5.seconds).of(Time.current)
      end
    end
  end

  describe "remove_expired_sessions" do
    it "only removes sessions older than the session timeout" do
      stub(ChorusConfig.instance).[]('session_timeout_minutes') { 20 }
      Timecop.freeze(Time.now) do
        expired_session = Session.new
        expired_session.save(:validate => false)
        Timecop.travel(2.minutes)
        current_session = Session.new
        current_session.save(:validate => false)
        Timecop.travel(19.minutes)
        Session.remove_expired_sessions
        Session.find_by_id(expired_session.id).should be_nil
        Session.find_by_id(current_session.id).should_not be_nil
      end
    end
  end
end
