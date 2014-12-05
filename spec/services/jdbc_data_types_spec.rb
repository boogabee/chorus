require 'spec_helper'

describe JdbcDataTypes do
  def self.it_maps_to_pretty_name(key, value)
    context "for #{key}" do
      it "maps to #{value}" do
        JdbcDataTypes.pretty_category_name(key).should == value
      end
    end
  end

  describe '.pretty_category_name' do
    it_maps_to_pretty_name 'string', 'STRING'
    it_maps_to_pretty_name 'integer', 'WHOLE_NUMBER'
    it_maps_to_pretty_name 'date', 'DATETIME'
    it_maps_to_pretty_name 'datetime', 'DATETIME'
    it_maps_to_pretty_name 'time', 'DATETIME'
    it_maps_to_pretty_name 'boolean', 'BOOLEAN'
    it_maps_to_pretty_name 'float', 'REAL_NUMBER'
    it_maps_to_pretty_name 'decimal', 'REAL_NUMBER'
    it_maps_to_pretty_name 'blob', 'OTHER'
    it_maps_to_pretty_name 'enum', 'OTHER'
  end
end
