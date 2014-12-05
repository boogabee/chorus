require 'spec_helper'

describe Gnip::DataSourceRegistrar do
  let(:owner) { users(:owner) }

  let(:data_source_attributes) do
    {
        :name => "new_gnip_data_source",
        :description => "some description",
        :stream_url => "https://historical.gnip.com/fake",
        :username => "gnip_username",
        :password => "gnip_password",
        :owner => owner
    }
  end

  describe ".create!" do

    context "with Valid credentials" do
      before do
        any_instance_of(ChorusGnip) do |c|
          mock(c).auth { true }
        end
      end

      it "save the data source" do
        data_source = Gnip::DataSourceRegistrar.create!(data_source_attributes, owner)

        data_source.should be_persisted
        data_source.name.should == "new_gnip_data_source"
        data_source.description.should == "some description"
        data_source.stream_url.should == "https://historical.gnip.com/fake"
        data_source.username.should == "gnip_username"
        data_source.password.should == "gnip_password"
        data_source.id.should_not be_nil
        data_source.should be_valid
      end

      it "makes a GnipDataSourceCreated event" do
        data_source = Gnip::DataSourceRegistrar.create!(data_source_attributes, owner)

        event = Events::GnipDataSourceCreated.last
        event.gnip_data_source.should == data_source
        event.actor.should == owner
      end
    end

    context "With Invalid credentials" do
      before do
        any_instance_of(ChorusGnip) do |c|
          mock(c).auth { false }
        end
      end
      it "raise an error" do
        expect {
          Gnip::DataSourceRegistrar.create!(data_source_attributes, owner)
        }.to raise_error(ApiValidationError)
      end
    end
  end

  describe ".update!" do

    let(:gnip_data_source) { gnip_data_sources(:default) }

    context "with Valid credentials" do

      let(:new_owner) { users(:not_a_member) }

      before do
        data_source_attributes.merge!({:owner => JSON.parse(new_owner.to_json)})
        any_instance_of(ChorusGnip) do |c|
          mock(c).auth { true }
        end
      end

      it "save the data source" do
        data_source = Gnip::DataSourceRegistrar.update!(gnip_data_source.id, data_source_attributes)

        data_source.should be_persisted
        data_source.name.should == "new_gnip_data_source"
        data_source.description.should == "some description"
        data_source.stream_url.should == "https://historical.gnip.com/fake"
        data_source.username.should == "gnip_username"
        data_source.password.should == "gnip_password"
        data_source.id.should_not be_nil
        data_source.should be_valid
      end

      it "should ignore an empty password" do
        data_source_attributes[:password] = ""
        data_source = Gnip::DataSourceRegistrar.update!(gnip_data_source.id, data_source_attributes)
        data_source.reload
        data_source.password.should_not be_blank
      end

      it "should strip out the owner" do
        data_source = Gnip::DataSourceRegistrar.update!(gnip_data_source.id, data_source_attributes)
        data_source.owner.should_not == new_owner
      end
    end

    context "With Invalid credentials" do
      before do
        any_instance_of(ChorusGnip) do |c|
          mock(c).auth { false }
        end
      end

      it "raise an error" do
        expect {
          Gnip::DataSourceRegistrar.update!(gnip_data_source.id, data_source_attributes)
        }.to raise_error(ApiValidationError)
      end
    end
  end
end