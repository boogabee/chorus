require_relative '../spec_helper'

describe "External Tables", :greenplum_integration do
  describe "importing a hadoop file into an external table" do
    let(:hdfs_data_source) { hdfs_data_sources(:real) }

    before do
      admin = users(:admin)
      admin.owned_workspaces.create!({:name => "integration_with_sandbox", :sandbox => GreenplumIntegration.real_database.schemas.first, :public => true}, :without_protection => true)

      any_instance_of(ExternalTable) do |table|
        stub(table).save { true }
      end

      login(admin)
    end

    it 'creates an external table', :hdfs_integration => true do
      # TODO 42385175: enable an integration label test for external tables
      pending "there seems to be some kind of backend error in the test setup"
      visit "#/hdfs_data_sources/#{hdfs_data_source.to_param}/browse"
      click_link '2_lines.csv'
      click_link 'Create as an external table'
      within_modal do
        fill_in 'tableName', :with => 'new_external_table'
        click_button 'Create External Table'
      end
      click_link 'new_external_table'
      page.should have_content 'Sandbox Table - HDFS External'
    end

    after do
      dataset = Dataset.find_by_name('new_external_table')
      dataset.destroy if dataset
    end
  end
end