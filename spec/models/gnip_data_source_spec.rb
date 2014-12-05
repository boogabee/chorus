require 'spec_helper'

describe GnipDataSource do
  it_behaves_like "a notable model" do
    let!(:note) do
      Events::NoteOnGnipDataSource.create!({
        :actor => users(:owner),
        :gnip_data_source => model,
        :body => "This is the body"
      }, :as => :create)
    end

    let!(:model) { FactoryGirl.create(:gnip_data_source) }
  end

  describe "validations" do
    it { should validate_presence_of :stream_url }
    it { should validate_presence_of :name }
    it { should validate_presence_of :username }
    it { should validate_presence_of :password }
    it { should validate_presence_of :owner }

    it { should validate_with DataSourceNameValidator }
    it { should validate_with DataSourceTypeValidator }

    it_should_behave_like 'a model with name validations' do
      let(:factory_name) { :gnip_data_source }
    end
  end

  describe "associations" do
    it { should belong_to(:owner).class_name('User') }
    it { should have_many :events }
    it { should have_many :activities }
  end

  it_should_behave_like "taggable models", [:gnip_data_sources, :default]

  it_behaves_like 'a soft deletable model' do
    let(:model) { gnip_data_sources(:default) }
  end

  it "destroying it creates an event" do
    subject = gnip_data_sources(:default)
    set_current_user(users(:admin))
    expect { subject.destroy }.to change { Events::DataSourceDeleted.count }.by(1)
    Events::DataSourceDeleted.last.data_source.should == subject
  end

  describe '#license_type' do
    its(:license_type) { should == subject.class.name }
  end
end
