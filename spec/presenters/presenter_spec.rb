require 'spec_helper'

describe Presenter, :type => :view do
  before do
    @model = FactoryGirl.build :user
    @presenter = Presenter.new(@model, view)
  end

  describe "#model" do
    it "returns the model" do
      @presenter.model.should == @model
    end
  end

  describe ".present_collection" do
    it "serializes an array" do
      Presenter.present_collection([@model], view, {}).should be_a(Array)
    end

    it "allows passing explicit presenter class for polymorphic collections" do
      class SpecExplicitPolymorphicPresenter < Presenter
        def to_hash
          {
            :name => model.name
          }
        end
      end

      hash = Presenter.present_collection([GpdbTable.new(:name => 'foo'), GpdbView.new(:name => 'bar')], view, {:presenter_class => 'SpecExplicitPolymorphicPresenter'})
      hash.should == [{:name => 'foo'}, {:name => 'bar'}]
    end
  end

  describe ".present" do
    let(:json) { Presenter.present(object_to_present, view) }

    context "with a single model" do
      let(:object_to_present) { FactoryGirl.build(:user) }

      context "when forbidden is true" do
        let(:json) { Presenter.present(object_to_present, view, {:forbidden => true}) }

        it "presents an empty hash" do
          json.should be_empty
        end
      end

      it "passes its options on" do
        mock(Presenter).present_model(object_to_present, { view: true }, { test: true })
        Presenter.new(object_to_present, { view: true }).present(object_to_present, { test: true })
      end

      it "presents a hash of the model" do
        json[:username].should == object_to_present.username
      end

      context "when complete_json? is true" do
        before do
          any_instance_of(UserPresenter, :complete_json? => true)
        end

        it "includes complete json" do
          json[:complete_json].should be_true
        end
      end

      context "when complete_json? is false" do
        before do
          any_instance_of(UserPresenter, :complete_json? => false)
        end

        it "does not include complete json" do
          json.should_not have_key(:complete_json)
        end
      end
    end

    context "with a paperclip attachment" do
      it "creates an ImagePresenter" do
        mock.proxy(ImagePresenter).new(@model.image, view, {})
        Presenter.present(@model.image, view)
      end
    end

    context "with a subclass of Events::Base" do
      it "creates an EventPresenter" do
        event = FactoryGirl.build(:data_source_created_event)
        mock.proxy(EventPresenter).new(event, view, {})
        Presenter.present(event, view)
      end
    end

    context "with an acts as taggable on tag" do
      it "should create a TagPresenter" do
        event = Tag.new(:name => 'bar')
        mock.proxy(TagPresenter).new(event, view, {})
        Presenter.present(event, view)
      end
    end

    context "with an active record relation" do

      let(:object_to_present) { User.where(:admin => true) }

      it "presents an array with a hash for each model in the relation" do
        json.length.should == 2
        json[0][:id].should == object_to_present[0].id
        json[1][:id].should == object_to_present[1].id
      end
    end

    context "with an array of models" do
      let(:object_to_present) do
        [
            FactoryGirl.build(:user, :username => 'name1'),
            FactoryGirl.build(:user, :username => 'name2')
        ]
      end

      it "presents an array with a hash for each model" do
        json.length.should == 2
        json[0][:username].should == object_to_present[0].username
        json[1][:username].should == object_to_present[1].username
      end

      context "when forbidden is true" do
        let(:json) { Presenter.present(object_to_present, view, {:forbidden => true}) }

        it "presents an array of empty hashes" do
          json.length.should == 2
          json.each { |j| j.should be_empty }
        end
      end
    end

    context "with a heterogeneous list of models" do
      let(:object_to_present) do
        [
            FactoryGirl.build(:user, :username => 'user'),
            FactoryGirl.build(:gpdb_data_source, :name => 'gpdb_data_source')
        ]
      end

      it "presents an array with a hash for each model" do
        json.length.should == 2
        json[0][:username].should == 'user'
        json[1][:name].should == 'gpdb_data_source'
      end
    end

    context "with an empty relation" do
      let(:object_to_present) { User.where(:username => "not_real") }

      it "presents an empty array" do
        json.should == []
      end
    end

    context "with an empty array" do
      let(:object_to_present) { [] }

      it "presents an empty array" do
        json.should == []
      end
    end
  end

  describe "complete_json?" do
    it "is false by default" do
      @presenter.complete_json?.should be_false
    end
  end
end
