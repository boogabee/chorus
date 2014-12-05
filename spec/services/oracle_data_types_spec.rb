require 'spec_helper'
require 'oracle_data_types'

describe OracleDataTypes do
  describe '#type_category' do
    def self.it_has_type_category(type, category, greenplum_type=nil)
      context "with a '#{type}' column" do
        it "has the #{category} category" do
          OracleDataTypes.pretty_category_name(type).should == category
        end

        unless greenplum_type.nil?
          it "has the #{greenplum_type} greenplum type" do
            OracleDataTypes.greenplum_type_for(type).should == greenplum_type
          end
        end
      end
    end

    it_has_type_category('BFILE', 'OTHER')
    it_has_type_category('BINARY_DOUBLE', 'REAL_NUMBER', 'double precision')
    it_has_type_category('BINARY_FLOAT', 'REAL_NUMBER', 'double precision')
    it_has_type_category('BLOB', 'OTHER')
    it_has_type_category('CHAR', 'STRING', 'character(1)')
    it_has_type_category('CLOB', 'LONG_STRING', 'text')
    it_has_type_category('DATE', 'DATETIME', 'timestamp without time zone')
    it_has_type_category('DECIMAL', 'REAL_NUMBER', 'double precision')
    it_has_type_category('FLOAT', 'REAL_NUMBER', 'double precision')
    it_has_type_category('INT', 'WHOLE_NUMBER', 'numeric')
    it_has_type_category('LONG', 'LONG_STRING')
    it_has_type_category('LONG RAW', 'OTHER')
    it_has_type_category('MLSLABEL', 'OTHER')
    it_has_type_category('NCHAR', 'STRING', 'character(1)')
    it_has_type_category('NCLOB', 'LONG_STRING', 'text')
    it_has_type_category('NUMBER', 'WHOLE_NUMBER', 'numeric')
    it_has_type_category('NVARCHAR2', 'STRING', 'character varying')
    it_has_type_category('RAW', 'OTHER')
    it_has_type_category('ROWID', 'LONG_STRING', 'text')
    it_has_type_category('TIMESTAMP', 'DATETIME', 'timestamp without time zone')
    it_has_type_category('UROWID', 'LONG_STRING', 'text')
    it_has_type_category('VARCHAR', 'STRING', 'character varying')
    it_has_type_category('VARCHAR2', 'STRING', 'character varying')
    it_has_type_category('XMLTYPE', 'OTHER')
    it_has_type_category('TIMESTAMP WITH TIME ZONE', 'DATETIME', 'timestamp with time zone')
    it_has_type_category('TIMESTAMP WITH LOCAL TIME ZONE', 'DATETIME', 'timestamp without time zone')
    it_has_type_category('TIMESTAMP(6)', 'DATETIME', 'timestamp without time zone')
  end
end
