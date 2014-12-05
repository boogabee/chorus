shared_examples_for "recent" do
  describe ".recent" do
    let!(:not_recent) do
      model= nil
      Timecop.freeze(8.days.ago) do
        model = FactoryGirl.create(described_class.name.underscore.gsub("events/base", "event").to_sym)
      end
      model
    end

    it "should not include comments older than 7 days" do
      described_class.recent.should_not include(not_recent)
    end
  end
end

shared_examples_for "a model with name validations" do
  it "cannot exceed 64 characters" do
    FactoryGirl.build(factory_name, :name => 'a'*64).should be_valid
  end

  it "cannot exceed 64 characters" do
    FactoryGirl.build(factory_name, :name => 'a'*65).should_not be_valid
  end

  it "can include integers" do
    FactoryGirl.build(factory_name, :name => "1aaa1").should be_valid
  end

  it "can include spaces" do
    FactoryGirl.build(factory_name, :name => "with space").should be_valid
  end

  it "can include special characters" do
    FactoryGirl.build(factory_name, :name => "-1test&").should be_valid
  end
end