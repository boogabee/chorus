require 'spec_helper'

describe DataSources::SchemasController do
  let(:user) { data_source.owner }
  let(:data_source) { data_sources(:oracle) }

  before do
    log_in user
    stub(Schema).visible_to { [schema_1, schema_2] }
  end

  describe "#index" do
    let(:schema_1) { FactoryGirl.create(:oracle_schema) }
    let(:schema_2) { FactoryGirl.create(:oracle_schema) }

    it 'returns a 200 status code' do
      get :index, :data_source_id => data_source.to_param
      response.status.should == 200
    end

    it 'presents the schemas' do
      mock_present do |models|
        models.should == [schema_1, schema_2]
      end

      get :index, :data_source_id => data_source.to_param
    end

    generate_fixture "oracleSchemaSet.json" do
      get :index, :data_source_id => data_source.to_param
    end

    context "user does not have access to the data source" do
      let(:user) { FactoryGirl.create(:user) }

      it "returns a 403" do
        get :index, :data_source_id => data_source.to_param
        response.status.should == 403
      end
    end
  end
end