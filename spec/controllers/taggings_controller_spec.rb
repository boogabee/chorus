require 'spec_helper'

describe TaggingsController do
  let(:user) { users(:owner) }

  before do
    log_in user
  end

  describe 'create' do
    let(:taggables) { [{:entity_id => entity.id, :entity_type => entity.class.name.underscore}] }

    describe 'adding tags' do
      let(:entity) { workfiles(:public) }
      let(:params) { { :taggables => taggables, :add => tag_name } }
      let(:tag_name) { 'alpha' }

      it 'adds the tags' do
        entity.tag_list = ['first-tag']
        entity.save!
        post :create, params
        response.code.should == '201'
        entity.reload.tags.map(&:name).should =~ ['first-tag', 'alpha']
      end

      context 'with a dataset' do
        let(:entity) { datasets(:table) }

        it 'adds the tags' do
          post :create, params
          response.code.should == '201'
          entity.reload.tags.map(&:name).should include 'alpha'
        end
      end

      context 'with duplicate tag names' do
        before do
          entity.tag_list = ["alpha"]
          entity.save!
        end

        it 'sets the tag only once' do
          post :create, params
          response.code.should == '201'
          entity.reload.tags.length.should == 1
        end
      end

      context 'when the user cannot see the work file' do
        let(:user) { users(:no_collaborators) }
        let(:entity) { workfiles(:private) }

        it 'returns unauthorized' do
          post :create, params
          response.code.should == '403'
        end
      end

      context 'when tags are more than 100 characters' do
        let(:tag_name) { 'a' * 101 }

        it 'raise a validation error' do
          post :create, params
          response.should_not be_success
          decoded_errors.fields.base.should have_key :TOO_LONG
        end
      end

      describe 'when tags differ only in case' do
        let(:tag_name) { 'panda' }
        before do
          entity.tag_list = ['Panda']
          entity.save!
        end

        it "sets a single tag on the workfile using the first tag's case" do
          post :create, params
          response.code.should == '201'
          entity.reload.tags.map(&:name).should == ['Panda']
        end
      end
    end

    describe 'removing tags' do
      let(:entity) { workfiles(:public) }
      let(:params) { { :taggables => taggables, :remove => tag_name} }
      let(:tag_name) { 'alpha' }

      before do
        entity.tag_list = ['alpha', 'beta', 'gamma']
        entity.save!
      end

      it 'removes tags' do
        post :create, params
        response.code.should == '201'
        entity.reload.tags.map(&:name).should =~ ['beta', 'gamma']
      end

      describe 'when the case is different' do
        let(:tag_name) { 'Alpha' }
        it "still removes the tag" do
          post :create, params
          response.code.should == '201'
          entity.reload.tags.map(&:name).should =~ ['beta', 'gamma']
        end
      end
    end

    context 'when multiple entities are being tagged' do
      let(:first_entity) { workfiles(:public) }
      let(:second_entity) { datasets(:table) }
      let(:tag_name) { 'alpha' }
      let(:taggables) { [
          {:entity_id => first_entity.id, :entity_type => first_entity.class.name.underscore},
          {:entity_id => second_entity.id, :entity_type => second_entity.class.name.underscore}
      ] }
      let(:params) { { :taggables => taggables, :add => tag_name} }

      it 'adds the tag to each entity' do
        post :create, params
        response.code.should == '201'
        first_entity.reload.tags.map(&:name).should include 'alpha'
        second_entity.reload.tags.map(&:name).should include 'alpha'
      end
    end
  end

  describe 'index' do
    let(:entity) { workfiles(:public) }
    let(:params) { { :entity_id => entity.id, :entity_type => entity.type } }

    it 'presents the tags for an entity' do
      mock_present do |taggings|
        taggings.should == entity.tags
      end
      get :index, params
    end

    context 'when the user cannot see the entity' do
      let(:user) { users(:no_collaborators) }
      let(:entity) { workfiles(:private) }

      it 'returns unauthorized' do
        get :index, params
        response.code.should == '403'
      end
    end
  end
end