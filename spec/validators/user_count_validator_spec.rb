require 'spec_helper'

class UserValidatable
  include ActiveModel::Validations
  validates_with UserCountValidator
  attr_accessor :user
end

describe UserCountValidator do
  let(:user) { UserValidatable.new }

  before do
    stub(License.instance).[](:collaborators) { 100 }
  end

  context 'when license does not limit user count' do
    before do
      stub(License.instance).limit_user_count? { false }
      mock(User).count.never
    end

    it 'validates without checking User.count' do
      user.should be_valid
    end
  end

  context 'when license limits user count' do
    before do
      stub(License.instance).limit_user_count? { true }
    end

    context 'on create' do
      it 'validates if adding the user would not exceed allowed' do
        stub(User).count { 99 }
        user.should be_valid
      end

      it 'does not validate if adding the user would exceed allowed' do
        stub(User).count { 100 }
        user.should_not be_valid
        stub(User).count { 101 }
        user.should_not be_valid
      end
    end
  end
end
