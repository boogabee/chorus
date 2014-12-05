require 'spec_helper'

describe UploadAccess do
  let(:controller) { ApplicationController.new }
  let(:access) { UploadAccess.new(controller) }
  let(:upload) { uploads(:default) }

  describe 'use?' do
    before do
      stub(controller).current_user { user }
    end

    context 'user is admin' do
      let(:user) { users(:admin) }

      it 'allows updating of the user' do
        access.can?(:use, upload).should be_true
      end
    end

    context 'user is not admin' do
      context 'user is original uploader' do
        let(:user) { upload.user }

        it 'should be allowed' do
          access.can?(:use, upload).should be_true
        end
      end

      context 'user another user' do
        let(:user) { users(:owner) }

        it 'should not be allowed' do
          access.can?(:use, upload).should be_false
        end
      end
    end
  end
end
