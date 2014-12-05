require 'minimal_spec_helper'
require 'stringio'
require_relative '../../app/models/chorus_config'

describe "get_full_java_options" do

  let(:root_path) { File.expand_path('../../..', __FILE__) }
  let(:script_path) { File.expand_path('../../../packaging/get_full_java_options.rb', __FILE__) }
  let(:chorus_config) { ChorusConfig.new(root_path) }

  before do
    @orig_stdout = $stdout
    $stdout = StringIO.new
  end

  after do
    $stdout = @orig_stdout
  end

  it "returns the java options from the chorus properties" do
    load script_path
    output.should == chorus_config['java_options'].to_s
  end

  def output
    $stdout.string
  end
end