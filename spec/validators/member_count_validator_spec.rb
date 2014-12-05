require 'spec_helper'

class MemberValidatable
  include ActiveModel::Validations
  validates_with MemberCountValidator
  attr_accessor :members
end

describe MemberCountValidator do
  let(:workspace) { MemberValidatable.new }

  context 'when license limits workspace membership' do
    before do
      stub(License.instance).limit_workspace_membership? { true }
    end

    it 'validates with 1 member' do
      mock(workspace.members).count { 1 }
      workspace.should be_valid
    end

    it 'does not validate with more than 1 member' do
      mock(workspace.members).count { 2 }
      workspace.should_not be_valid
    end
  end

  context 'when license does not limit workspace membership' do
    before do
      stub(License.instance).limit_workspace_membership? { false }
    end

    it 'validates without checking count' do
      mock(workspace.members).count.never
      workspace.should be_valid
    end
  end
end
