require 'spec_helper'
require 'java'

describe Hdfs::QueryService, :hdfs_integration do
  let(:hdfs_params) { HdfsIntegration.data_source_config }
  let(:service) { Hdfs::QueryService.new(hdfs_params["host"], hdfs_params["port"], hdfs_params["username"], nil, false, []) }

  before :all do
    # silence the HDFS log output from failed version connections
    @java_stdout = java.lang.System.out
    @java_stderr = java.lang.System.err
    devnull = java.io.PrintStream.new(java.io.FileOutputStream.new("/dev/null"))
    com.emc.greenplum.hadoop.Hdfs.logger_stream = devnull
    java.lang.System.setOut(devnull)
    java.lang.System.setErr(devnull)
  end

  after :all do
    java.lang.System.setOut(@java_stdout)
    java.lang.System.setErr(@java_stderr)
  end

  describe "data_source_version" do
    context "existing hadoop server" do
      let(:data_source) do
        HdfsDataSource.new hdfs_params
      end

      it "returns the hadoop version" do
        version = described_class.version_of(data_source)
        version.should == hdfs_params['adapter_version']
      end
    end

    context "nonexistent hadoop server" do
      let(:data_source) { "garbage" }
      let(:port) { 8888 }
      let(:username) { "pivotal" }
      let(:nonexistent_data_source) do
        HdfsDataSource.new :host => data_source, :port => port, :username => username
      end

      it "raises ApiValidationError and prints to log file" do
        Timecop.freeze(Time.current)
        mock(Rails.logger).error("#{Time.current.strftime("%Y-%m-%d %H:%M:%S")} ERROR: Within JavaHdfs connection, failed to establish connection to #{data_source}:#{port}")
        expect { described_class.version_of(nonexistent_data_source) }.to raise_error(ApiValidationError) { |error|
          error.record.errors.get(:connection).should == [[:generic, { :message => "Unable to determine HDFS server version or unable to reach server at #{data_source}:#{port}. Check connection parameters." }]]
        }
        Timecop.return
      end
    end
  end

  describe "#accessible?" do
    context "when the hadoop server can be reached" do
      let(:reachable_data_source) do
        HdfsDataSource.new hdfs_params
      end

      it "returns true" do
        Hdfs::QueryService.accessible?(reachable_data_source).should be_true
      end
    end

    context "when the hadoop server cannot be reached" do
      let(:data_source) { "garbage" }
      let(:port) { 8888 }
      let(:username) { "pivotal" }
      let(:unreachable_data_source) do
        HdfsDataSource.new :host => data_source, :port => port, :username => username
      end

      it "returns false" do
        Hdfs::QueryService.accessible?(unreachable_data_source).should be_false
      end
    end
  end

  describe "#list" do
    context "listing root with sub content" do
      it "returns list of content for root directory" do
        response = service.list("/")
        response.count.should > 2
      end
    end

    context "listing empty directory" do
      it "should return an array with zero length" do
        response = service.list("/empty/")
        response.should have(0).files
      end
    end

    context "listing non existing directory" do
      it "should return an error" do
        expect { service.list("/non_existing/") }.to raise_error(Hdfs::DirectoryNotFoundError)
      end
    end

    context "connection is invalid" do
      let(:service) { Hdfs::QueryService.new("bagbage", "8020", "pivotal", "0.20.1gp", false, []) }

      it "raises an exception" do
        expect { service.list("/") }.to raise_error(Hdfs::DirectoryNotFoundError)
      end
    end
  end

  describe "#details" do
    it "fetches details" do
      hdfs_entry_details = service.details("/")
      hdfs_entry_details.owner.should_not be_nil
    end

    context "non existing file" do
      it "should return an error" do
        expect { service.details("/non_existing/no_where") }.to raise_error(Hdfs::FileNotFoundError)
      end
    end

    context "connection is invalid" do
      let(:service) { Hdfs::QueryService.new("bagbage", "8020", "pivotal", "0.20.1gp", false, []) }

      it "raises an exception" do
        expect { service.details("/") }.to raise_error(Hdfs::FileNotFoundError)
      end
    end
  end

  describe "#show" do
    before do
      any_instance_of(com.emc.greenplum.hadoop.Hdfs) do |java_hdfs|
        stub(java_hdfs).content(is_a(String), 200) { file_content }
      end
    end

    context "show an existing file" do
      let(:file_content) { "a, b, c" }

      it "returns part of the content" do
        response = service.show("/data/test.csv")
        response.should_not be_empty
        response.should include("a, b, c")
      end
    end

    context "show a non existing file" do
      let(:file_content) { nil }

      it "should return an error" do
        expect { service.show("/file") }.to raise_error(Hdfs::FileNotFoundError)
      end
    end
  end

  describe '#delete' do
    before do
      any_instance_of(com.emc.greenplum.hadoop.Hdfs) do |java_hdfs|
        stub(java_hdfs).delete(is_a(String)) { response }
      end
    end

    context 'when the delete is successful' do
      let(:response) { true }

      it 'returns true' do
        service.delete('/some/path').should be_true
      end
    end

    context 'when the delete is unsuccessful' do
      let(:response) { false }

      it 'returns false' do
        service.delete('/some/path').should be_false
      end
    end
  end

  describe '#import_data' do
    let(:stream) { {} }

    before do
      any_instance_of(com.emc.greenplum.hadoop.Hdfs) do |java_hdfs|
        stub(java_hdfs).import_data(is_a(String), anything, false) { response }
      end
    end

    context 'when the import is successful' do
      let(:response) { OpenStruct.new :success? => true }

      it 'returns true' do
        service.import_data('/some/path', stream).should be_true
      end
    end

    context 'when the import is unsuccessful' do
      let(:response) { OpenStruct.new :success? => false, :message => 'nope' }

      it 'raises' do
        expect { service.import_data('/some/path', stream) }.to raise_error(StandardError, 'nope')
      end
    end
  end
end
