module DataSourceHelpers
  def select_and_do_within_data_source(value)
    page.should have_xpath('//select[@id="data_sources"]/option[4]')
    find(".data_source_new.dialog").should have_content("Data Source Type")
    page.find("#data_sources-button span.ui-selectmenu-text").should have_content("Select one")
    select_item("select.data_sources", value)
    page.find("#data_sources-button span.ui-selectmenu-text").should have_no_content("Select one")
    within ".data_sources_form.#{value}" do
      yield
    end
  end
end
