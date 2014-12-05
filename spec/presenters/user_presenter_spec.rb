require 'spec_helper'

describe UserPresenter, :type => :view do
  let(:user) { users(:owner) }
  let(:options) { {} }
  let(:presenter) { UserPresenter.new(user, view, options) }

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    it "includes the right keys" do
      hash.should have_key(:username)
      hash.should have_key(:id)
      hash.should have_key(:first_name)
      hash.should have_key(:last_name)
      hash.should have_key(:tags)
    end

    it "uses the image presenter to serialize the image urls" do
      hash[:image].to_hash.should == (ImagePresenter.new(user.image, view).presentation_hash)
    end

    it "does not include unwanted keys" do
      hash.should_not have_key(:password_digest)
    end

    context "When rendering the activity stream" do
      let(:options) { {:activity_stream => true} }

      it "renders the appropriate keys" do
        hash[:id].should == user.id
        hash[:username].should == user.username
        hash[:first_name].should == user.first_name
        hash[:last_name].should == user.last_name
        hash[:entity_type].should == 'user'
        hash[:image].to_hash.should == (ImagePresenter.new(user.image, view).presentation_hash)
        hash[:is_deleted].should == user.deleted?
        hash.keys.size.should == 7
      end
    end

    context "rendering succinct json" do
      let(:options) { {:succinct => true} }

      it "renders the appropriate keys" do
        hash[:id].should == user.id
        hash[:username].should == user.username
        hash[:first_name].should == user.first_name
        hash[:last_name].should == user.last_name
        hash[:entity_type].should == 'user'
        hash[:image].to_hash.should == (ImagePresenter.new(user.image, view).presentation_hash)
        hash[:is_deleted].should == user.deleted?
        hash.keys.size.should == 7
      end
    end
  end

  describe "complete_json?" do
    context "when rendering activities" do
      let(:options) { {:activity_stream => true} }
      it "is not true" do
        presenter.complete_json?.should_not be_true
      end
    end

    context "when not rendering activities" do
      it "is true" do
        presenter.complete_json?.should be_true
      end
    end
  end
end
