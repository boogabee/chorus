require 'minimal_spec_helper'
require 'stringio'
require_relative '../../app/models/chorus_config'

describe "get_solr_port" do

  let(:root_path) { File.expand_path('../../..', __FILE__) }
  let(:script_path) { File.expand_path('../../../packaging/get_solr_port.rb', __FILE__) }
  let(:chorus_config) { ChorusConfig.new(root_path) }

  before do
    @orig_stdout = $stdout
    @original_env, ENV["RAILS_ENV"] = ENV["RAILS_ENV"], "test"
    $stdout = StringIO.new
  end

  after do
    ENV["RAILS_ENV"] = @original_env
    $stdout = @orig_stdout
  end

  it "returns the solr port from the chorus properties" do
    load script_path
    output.should == chorus_config['solr_port'].to_s
  end

  def output
    $stdout.string
  end
end