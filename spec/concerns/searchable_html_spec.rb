require 'spec_helper'
require 'sunspot'

describe SearchableHtml do
  describe ".searchable_html" do
    before do
      Sunspot.session = Sunspot.session.original_session

      class SearchableHtmlTestClass < ActiveRecord::Base
        @columns = []
        include SearchableHtml

        attr_accessor :html_field, :id
        attr_accessible :html_field

        searchable_html :html_field
      end
    end

    after do
      Sunspot.searchable.instance_variable_get(:@name_to_klass).delete(SearchableHtmlTestClass.name.to_sym)
    end

    it "removes tags from the body" do
      VCR.use_cassette("searchable_html") do
        obj = SearchableHtmlTestClass.new(:html_field => 'hello <b>twinkletwinklelittlestar</b>')
        obj.id = 1
        obj.solr_index
        Sunspot.commit

        results = SearchableHtmlTestClass.search { fulltext 'twinkletwinklelittlestar' }
        results.hits[0].stored('html_field')[0].should == 'hello twinkletwinklelittlestar'
      end
    end
  end
end