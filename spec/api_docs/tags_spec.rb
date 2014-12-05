require 'spec_helper'

resource 'Tags' do
  let(:user) { users(:owner) }
  let(:workfile) { workfiles("sql.sql") }

  before do
    log_in user
  end

  post '/taggings' do
    parameter :taggables, 'An array of objects to be tagged, each with form {entity_id: <num>, entity_type: <type>}'
    parameter :add, 'Tag name (100 characters or less)'
    required_parameters :taggables

    let(:taggables) { [{entity_id: workfile.to_param, entity_type: Workfile}] }
    let(:add) { 'alpha' }

    example_request 'Adding a tag to multiple entities' do
      status.should == 201
    end
  end

  post '/taggings' do
    parameter :taggables, 'An array of objects to be tagged, each with form {entity_id: <num>, entity_type: <type>}'
    parameter :remove, 'Tag name'
    required_parameters :taggables

    before do
      workfile.tag_list = ['alpha']
    end

    let(:taggables) { [{entity_id: workfile.to_param, entity_type: Workfile}] }
    let(:remove) { 'alpha' }

    example_request 'Removing a tag from multiple entities' do
      status.should == 201
    end
  end

  get '/taggings' do
    parameter :entity_id, 'The id of taggable entity'
    parameter :entity_type, 'The type of the taggable entity (workfile, dataset, etc)'
    required_parameters :entity_id, :entity_type

    before do
      workfile.tag_list = ['alpha']
    end

    let(:entity_id) { workfile.id }
    let(:entity_type) { 'workfile' }

    example_request 'Get the list of tags for an entity' do
      status.should == 200
    end
  end

  get '/tags' do
    parameter :query, 'String to search tags for'

    let(:query) { "something" }

    example_request 'Search tags' do
      status.should == 200
    end
  end

  put '/tags/:id' do
    parameter :id, 'Id of the tag to rename'
    parameter :name, 'Tag name (100 characters or less)'

    let(:id) { Tag.first.id }
    let(:name) { "myTag" }

    example_request 'Rename a tag' do
      status.should == 200
    end
  end

  delete '/tags/:id' do
    let(:user) { users(:admin) }
    let(:id) { Tag.first.id }

    parameter :id, 'Id of the tag to delete'


    example_request 'Delete a tag' do
      status.should == 200
    end
  end
end
