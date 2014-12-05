require 'spec_helper'

describe DataSourceConnection do
  # see greenplum_connection_spec for Greenplum specific specs

  describe ".escape_like_string" do
    it "escapes characters _ and %" do
      c = DataSourceConnection::LIKE_ESCAPE_CHARACTER
      like_string = "e_i%w$on_fe#ino%f"
      escaped_string = "e#{c}_i#{c}%w$on#{c}_fe#ino#{c}%f"
      DataSourceConnection.escape_like_string(like_string).should == escaped_string
    end

    it "escapes the escape character" do
      c = DataSourceConnection::LIKE_ESCAPE_CHARACTER
      like_string = "query#{c}string#{c}"
      escaped_string = "query#{c + c}string#{c + c}"
      DataSourceConnection.escape_like_string(like_string).should == escaped_string
    end
  end

  describe "Error" do
    it "can be initialized with an exception" do
      original_exception = Exception.new('error!')
      exception = DataSourceConnection::Error.new(original_exception)
      exception.message.should == original_exception.message
    end

    it "can be initialized with an error_type" do
      exception = DataSourceConnection::Error.new(:I_AM_AN_ERROR_TYPE)
      exception.error_type.should == :I_AM_AN_ERROR_TYPE
    end
  end

  describe "InvalidCredentials" do
    it "can be initialized with a data source" do
      data_source = data_sources(:default)
      exception = DataSourceConnection::InvalidCredentials.new(data_source)
      exception.subject.should == data_source
    end
  end
end