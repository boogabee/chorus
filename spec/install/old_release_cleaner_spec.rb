require 'minimal_spec_helper'
require 'fakefs/spec_helpers'
require_relative "../../packaging/install/old_release_cleaner"

describe OldReleaseCleaner do
  include FakeFS::SpecHelpers
  let(:logger) { Object.new }
  let(:cleaner) { OldReleaseCleaner.new(logger) }

  before do
    stub(logger).log {}
  end

  context "when the given directories don't have the same base dir" do
    let(:new_version) { "/hamburger/old" }
    let(:old_version) { "/cheeseburger/new" }

    before do
      FileUtils.mkdir_p new_version
      FileUtils.mkdir_p old_version
    end

    it "should puke" do
      expect { cleaner.remove_except(new_version, old_version) }.to raise_exception
    end
  end

  context "when the given directories do have the same base dir" do
    let(:new_version) { "/cheeseburger/old" }
    let(:old_version) { "/cheeseburger/new" }
    let(:really_old_version) { "/cheeseburger/really_old" }
    let(:really_really_old_version) { "/cheeseburger/really_really_old" }
    let(:random_file) { "/cheeseburger/condiments.txt" }

    before do
      [new_version, old_version, really_old_version, really_really_old_version].each do |version|
        FileUtils.mkdir_p version + '/subdir'
      end
      FileUtils.touch(random_file)
    end

    it "removes all of the directories in the destination_path, except the new and previous versions" do
      cleaner.remove_except(new_version, old_version)

      Dir.exists?(new_version).should be_true
      Dir.exists?(old_version).should be_true
      Dir.exists?(really_old_version).should be_false
      Dir.exists?(really_really_old_version).should be_false
    end

    it "does not remove other files" do
      cleaner.remove_except(new_version, old_version)
      File.exists?(random_file).should be_true
    end

    it "logs a message for each directory it removes" do
      mock(logger).log("Removing outdated release: #{really_old_version}")
      mock(logger).log("Removing outdated release: #{really_really_old_version}")
      do_not_allow(logger).log("Removing outdated release: #{random_file}")
      cleaner.remove_except(new_version, old_version)
    end
  end
end
