require 'spec_helper'

describe SoftDelete do
  before do
    @test_class = Class.new(ActiveRecord::Base) do
      self.table_name = 'users'
      include SoftDelete

      attr_accessor :required_field
      validates_presence_of :required_field
    end
  end

  let(:test_object) do
    @test_class.new.tap do |model|
      model.save!(:validate => false)
    end
  end

  it "does not validate on destroy" do
    test_object.destroy
    @test_class.find_by_id(test_object.id).should be_nil
  end
end