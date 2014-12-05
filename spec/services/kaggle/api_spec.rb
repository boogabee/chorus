require 'spec_helper'
require 'fakefs/spec_helpers'

# We created these users to check emails.
#username: bbanner
#id: 63766
#email: 2093j0qur890w3ur0@mailinator.com

#username: tstark
#id: 63767
#email: jg93904u9fhwe9ry@mailinator.com

describe Kaggle::API, :kaggle_API => true do
  include KaggleSpecHelpers

  before :all do
    api_key = ChorusConfig.instance['kaggle']['api_key']
    VCR.configure do |c|
      c.filter_sensitive_data('<SUPPRESSED_KAGGLE_API_KEY>', :filter_kaggle_api_key_param) do |interaction|
        api_key
      end
    end
  end

  describe ".users" do
    context "when kaggle api is enabled" do
      let(:kaggle_api_url) {
        "https://www.kaggle.com/connect/chorus-beta/directory?apiKey=#{ChorusConfig.instance['kaggle']['api_key']}"
      }

      before do

        stub(Kaggle::API).enabled? { true }
        FakeWeb.register_uri(:get, kaggle_api_url,
                             :body => File.read(Rails.root + "spec/fixtures/kaggleSearchResults.json"),
                             :status => ["200", "Success"])
      end

      it "returns a list of Kaggle::Users" do
        users = Kaggle::API.users

        users.count.should > 0
        users.first.should be_a Kaggle::User
        users.first['id'].should_not be_nil
      end

      context "when fetching the users fails" do
        before do
          FakeWeb.register_uri(:get, kaggle_api_url,
                               :status => ["401", "Unauthorized"])
        end

        it "raises a NotReachable error" do
          expect {
            users = Kaggle::API.users
          }.to raise_error Kaggle::API::NotReachable
        end
      end
    end

    context "when kaggle api is disabled" do
      include FakeFS::SpecHelpers

      before :all do
        @kaggle_users = File.read(Rails.root + "spec/fixtures/kaggleSearchResults.json")
      end

      before do
        stub(Kaggle::API).enabled? { false }
      end

      context "when the kaggleSearchResult.json exists" do
        before do
          dir = Rails.root.join("demo_data")
          FileUtils.mkdir_p(dir.to_s)
          File.open(dir.join('kaggleSearchResults.json').to_s, 'w') do |f|
            f << @kaggle_users
          end
        end

        it "gets the users from the file" do
            users = Kaggle::API.users

            users.count.should > 0
            users.first.should be_a Kaggle::User
            users.first['full_name'].should == JSON.parse(@kaggle_users)['users'].first['LegalName']
        end
      end

      context "when the kaggleSearchResults.json does not exist" do
        it "raises a NotReachable error" do
          File.exist?(Rails.root.join('demo_data', 'kaggleSearchResults.json')).should be_false

          expect {
            users = Kaggle::API.users
          }.to raise_error Kaggle::API::NotReachable
        end
      end
    end

    describe "specifying optional filters" do
      before do
        mock(Kaggle::API).fetch_users.any_number_of_times {
          kaggle_users_api_result
        }
      end

      it "can filter by greater" do
        users = Kaggle::API.users(:filters => ["rank|greater|10"])

        users.first["KaggleRank"].should > 10
        users.length.should == Kaggle::API.users.select { |user| user["KaggleRank"] > 10 }.count
      end

      it "can filter by equal" do
        users = Kaggle::API.users(:filters => ["rank|equal|42"])

        users.length.should == Kaggle::API.users.select { |user| user["KaggleRank"] == 42 }.count
        users.first["KaggleRank"].should == 42
      end

      # API doesn't return any list data fields yet
      it "can filter by equal on list data" do
        users = Kaggle::API.users(:filters => ["past_competition_types|equal|geospatial"])
        users.length.should == 1
        users.first["PastCompetitionTypes"].should include "Geospatial"
      end

      it "ignores blank filter values" do
        users = Kaggle::API.users(:filters => ["rank|greater|"])
        users.length.should == Kaggle::API.users.count
      end

      it "ignores blank filter values on list data" do
        users = Kaggle::API.users(:filters => ["favorite_technique|includes|"])
        users.length.should == Kaggle::API.users.count
      end

      it "searches software, techniques and location by substring match" do
        users = Kaggle::API.users(:filters => ["favorite_technique|includes|matrix",
                                               "favorite_software|includes|r",
                                               "location|includes|fRaNcISco"])

        users.first['FavoriteTechnique'].should include "Matrix Methods"
        users.first['FavoriteSoftware'].should include "R"
        users.first['Location'].should include "San Francisco"

        users.length.should == Kaggle::API.users.select do |user|
          user["FavoriteTechnique"].match(/matrix/i) &&
          user["FavoriteSoftware"].match(/r/i) &&
          user["Location"].match(/francisco/i)
        end.count
      end

      it "doesn't break if you pass in a number" do
        expect {
          Kaggle::API.users(:filters => ["favorite_technique|includes|1234"])
        }.to_not raise_error
      end

      it "doesn't break with an invalid key" do
        users = Kaggle::API.users(:filters => ["notakey|includes|foo"])
        users.length.should == 0
      end
    end
  end

  describe ".send_message" do
    let(:user_ids) { [63766,63767] }
    let(:params) { {
        "subject" => "some subject",
        "replyTo" => "test@fun.com",
        "htmlBody" => "message body",
        "userId" => user_ids
    } }

    context "when kaggle is enabled" do
      let(:api_key) { ChorusConfig.instance['kaggle']['API_key'] }

      before do
        stub(Kaggle::API).enabled? { true }
      end

      it "succeeds with valid ids" do
        VCR.use_cassette('kaggle_message_success', :tag => :filter_kaggle_api_key_param) do
          described_class.send_message(params).should be_true
        end
      end

      context "with an invalid user id" do
        let(:user_ids) { [63766,99999999] }

        it "raises a MessageFailed exception" do
          VCR.use_cassette('kaggle_message_fail', :tag => :filter_kaggle_api_key_param) do
            expect {
              described_class.send_message(params)
            }.to raise_exception(Kaggle::API::MessageFailed)
          end
        end
      end

      context "when the API times out" do
        it "raises a kaggle error" do
          any_instance_of(Net::HTTP) do |http|
            stub(http).request { raise Timeout::Error.new }
          end

          expect {
            described_class.send_message(params)
          }.to raise_exception(Kaggle::API::MessageFailed,
                               'Could not connect to the Kaggle server')
        end
      end
    end

    context "when kaggle api is not enabled" do
      before do
        stub(Kaggle::API).enabled? { false }
      end

      it "doesn't do anything" do
        dont_allow(JSON).parse(anything)

        VCR.use_cassette('kaggle_message_success', :tag => :filter_kaggle_api_key_param) do
          described_class.send_message(params).should be_nil
        end
      end
    end
  end

  describe ".enabled?" do
    it "is true if enabled is set to true in the config file" do
      stub(ChorusConfig.instance).[]('kaggle') { { 'enabled' => true } }
      #ChorusConfig.instance['kaggle']['enabled'] = true
      Kaggle::API.enabled?.should be_true
    end

    it "is false" do
      #ChorusConfig.instance['kaggle']['enabled'] = false
      stub(ChorusConfig.instance).[]('kaggle') { { 'enabled' => false } }
      Kaggle::API.enabled?.should be_false
    end

    it "is an invalid value" do
      stub(ChorusConfig.instance).[]('kaggle') { { 'enabled' => "HELLO" } }
      Kaggle::API.enabled?.should be_false
    end
  end
end