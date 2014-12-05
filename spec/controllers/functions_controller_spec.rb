require 'spec_helper'

describe FunctionsController do
  ignore_authorization!

  let(:user) { users(:owner) }

  before do
    log_in user
  end

  describe "#index" do
    let(:schema) { schemas(:default) }
    let(:functions) { [
          SchemaFunction.new("a_schema", "ZOO", "sql", "text", [], "{text}", "Hi!!", "awesome"),
          SchemaFunction.new("a_schema", "hello", "sql", "int4", %w{arg1, arg2}, "{text, int4}", "Hi2", "awesome2"),
          SchemaFunction.new("a_schema", "foo", "sql", "text", %w{arg1}, "{text}", "hi3", "cross joins FTW")
    ]}

    context 'for a gpdb schema' do
      before do
        any_instance_of(GpdbSchema) do |schema|
          mock(schema).stored_functions.with_any_args { functions }
        end
      end

      it 'should list all the functions in the schema' do
        mock_present { |model| model.should == functions }

        get :index, :schema_id => schema.to_param
        response.code.should == '200'
      end

      it_behaves_like "a paginated list" do
        let(:params) {{ :schema_id => schema.to_param }}
      end

      it "should check for permissions" do
        mock(subject).authorize! :show_contents, schema.data_source
        get :index, :schema_id => schema.to_param
      end

      generate_fixture "schemaFunctionSet.json" do
        get :index, :schema_id => schema.to_param
      end
    end

    context 'for a pg schema' do
      before do
        any_instance_of(PgSchema) do |schema|
          mock(schema).stored_functions.with_any_args { functions }
        end
      end

      let(:schema) { schemas(:pg) }

      it 'should list all the functions in the schema' do
        mock_present { |model| model.should == functions }

        get :index, :schema_id => schema.to_param
        response.code.should == '200'
      end
    end
  end
end
