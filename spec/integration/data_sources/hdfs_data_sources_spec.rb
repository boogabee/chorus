require_relative '../spec_helper'

describe 'Data Sources', :hdfs_integration do
  describe 'adding a hadoop data source' do
    include DataSourceHelpers

    before do
      login(users(:admin))
      visit('#/data_sources')
      click_link 'Add Data Source'
    end

    it 'creates an hadoop data source' do
      within_modal do
        select_and_do_within_data_source 'register_existing_hdfs' do
          fill_in 'name', :with => 'BestHadoop'
          fill_in 'host', :with => HdfsIntegration.data_source_config['host']
          fill_in 'port', :with => HdfsIntegration.data_source_config['port']
          fill_in 'username', :with => HdfsIntegration.data_source_config['username']
          fill_in 'groupList', :with => HdfsIntegration.data_source_config['group_list']
          select_item('[name=hdfsVersion]', 'Pivotal HD 2.0')
        end
        click_button 'Add Data Source'
      end

      find('.hdfs_data_source ul').should have_content('BestHadoop')
    end
  end
end