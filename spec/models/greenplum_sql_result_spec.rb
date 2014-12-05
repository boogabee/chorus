require 'spec_helper'

describe GreenplumSqlResult, :greenplum_integration do
  let(:data_source) { GreenplumIntegration.real_data_source }
  let(:schema) { GreenplumIntegration.real_database.schemas.where(:name => "test_schema").first }
  let(:account) { data_source.owner_account }
  let(:table_name) { "binary_columns_table" }

  before do
    schema.connect_with(account).execute("CREATE TABLE #{table_name} (col1 float8, col2 float8)")
    schema.connect_with(account).execute("INSERT INTO #{table_name} VALUES(2.3, 5.3)")
  end

  after do
    schema.connect_with(account).execute("DROP TABLE #{table_name}")
  end

  it "properly formats binary floats" do
    rs = schema.connect_with(account).prepare_and_execute_statement "SELECT * FROM \"#{table_name}\""
    rs.rows[0][0].should == "2.3"
    rs.rows[0][1].should == "5.3"
  end
end