# encoding: UTF-8

module Capybara
  module Helpers
    class << self
      ##
      #
      # Normalizes whitespace space by stripping leading and trailing
      # whitespace and replacing sequences of whitespace characters
      # with a single space.
      #
      # @param [String] text     Text to normalize
      # @return [String]         Normalized text
      #
      def normalize_whitespace(text)
        # http://en.wikipedia.org/wiki/Whitespace_character#Unicode
        # We should have a better reference.
        # See also http://stackoverflow.com/a/11758133/525872
        text.to_s.gsub(/[\s\u0085\u00a0\u1680\u180e\u2000-\u200a\u2028\u2029\u202f\u205f\u3000]+/, ' ').strip
      end
    end
  end
end

module CapybaraHelpers
  def current_route
    URI.parse(current_url).fragment
  end

  def attach_file(locator, path)
    element = find(:file_field, locator)
    id = element['id']
    jquery_locator = id.present? ? "#" + id : "input[name=\"#{locator}\"]"
    # workaround to allow selenium to click the element
    page.execute_script("$('#{jquery_locator}').removeClass('file-input');")
    element.set(path)
  end

  def page_title_should_be(title)
    within(".content_header") do
      page.should have_selector("h1", :text => title)
    end
  end

  def select_item(selector, value)
    page.execute_script("$('#{selector}').val('#{value}')")
    page.execute_script("$('#{selector}').selectmenu('refresh')")
    page.execute_script("$('#{selector}').change()")
  end

  def wait_for_page_load
    page.should have_selector(".main_content")
    page.should have_no_selector(".loading_section")
  end
end