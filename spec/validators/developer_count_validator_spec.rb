require 'spec_helper'

class DeveloperValidatable
  include ActiveModel::Validations
  validates_with DeveloperCountValidator
  attr_accessor :developer
end

describe DeveloperCountValidator do

  let(:user) { DeveloperValidatable.new }

  before do
    stub(License.instance).[](:developers) { 10 }
    stub(user).developer_changed? { true }
  end

  context 'when license does not limit developer count' do
    before do
      stub(License.instance).limit_user_count? { false }
      mock(user).developer?.never
      mock(User).developer_count.never
    end

    it 'validates without checking User#developer? or User.developer_count' do
      user.should be_valid
    end
  end

  context 'when license limits developer count' do
    before do
      stub(License.instance).limit_user_count? { true }
    end

    context 'user is designated as a developer' do
      before do
        mock(user).developer? { true }
      end

      it 'validates if the number of existing devs is less than the limit' do
        stub(User).developer_count { 9 }
        user.should be_valid
      end

      context 'developer was changed to true' do
        before do
          stub(user).developer_changed? { true }
        end

        it 'does not validate if the number of existing devs is greater than or equal to the limit' do
          stub(User).developer_count { 10 }
          user.should_not be_valid
        end
      end

      context 'an existing developer' do
        before do
          stub(user).developer_changed? { false }
        end

        it 'validates if the number of existing devs is equal to the limit' do
          stub(User).developer_count { 10 }
          user.should be_valid
        end

        it 'does not validate if the number of existing devs is greater than the limit' do
          stub(User).developer_count { 11 }
          user.should_not be_valid
        end
      end

    end

    context 'user is not designated as a developer' do
      before do
        mock(user).developer? { false }
      end

      [9,10,11].each do |count|
        context "when current dev count is #{count}" do
          before { stub(User).developer_count { count } }
          it('validates') { user.should be_valid }
        end
      end
    end
  end
end
