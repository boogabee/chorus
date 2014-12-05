def within_modal(&block)
  modal_selector = "#facebox"
  page.should have_selector(modal_selector)
  within(modal_selector, &block)
  page.should have_no_selector(modal_selector)
end