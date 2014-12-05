require 'spec_helper'
require 'fakefs/spec_helpers'

describe SensitiveFileChecker do
  include FakeFS::SpecHelpers
  file_names = %W{
        secret.token
        secret.key
        chorus.properties
      }

  let(:file_prefix) { Rails.root + 'config'}
  let(:files) { file_names.collect { |file| file_prefix + file } }

  before do
    FileUtils.mkdir_p file_prefix
    files.each do |file|
      FileUtils.touch file
      FileUtils.chmod 0600, file
    end
  end

  describe "check" do
    it "returns true if all files are the correct mode" do
      SensitiveFileChecker.check.should be_true
    end

    file_names.each do |file|
      it "returns false if #{file} is readable by anybody else" do
        FileUtils.chmod 0640, file_prefix + file
        SensitiveFileChecker.check.should be_false
        FileUtils.chmod 0604, file_prefix + file
        SensitiveFileChecker.check.should be_false
      end

      it "returns false if #{file} is writable by anybody else" do
        FileUtils.chmod 0620, file_prefix + file
        SensitiveFileChecker.check.should be_false
        FileUtils.chmod 0602, file_prefix + file
        SensitiveFileChecker.check.should be_false
      end
    end
  end

  describe "unprotected_files" do
    it "returns the paths to all files that are unprotected" do
      files[0..1].each do |file|
        FileUtils.chmod 0644, file
      end

      SensitiveFileChecker.unprotected_files.should =~ files[0..1].collect(&:to_s)
    end
  end

  describe "errors" do
    it "returns an array of error messages" do
      files[0..1].each do |file|
        FileUtils.chmod 0644, file
      end

      SensitiveFileChecker.errors.should =~ files[0..1].collect {|f| "FATAL ERROR: #{f} is readable or writable by other users."}
    end
  end
end
