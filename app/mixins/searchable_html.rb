module SearchableHtml
  extend ActiveSupport::Concern
  include ActionView::Helpers::SanitizeHelper

  module ClassMethods
    def searchable_html(field, options = {})
      searchable options do
        text field, :stored => true do
          html = send field
          strip_tags html
        end
      end
    end
  end
end