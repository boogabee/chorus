require 'stringio'
require 'spec_helper'
require_relative '../../app/models/chorus_config'

describe "get_jruby_options" do

  let(:root_path) { File.expand_path('../../..', __FILE__) }
  let(:script_path) { File.expand_path('../../../packaging/get_jruby_options.rb', __FILE__) }

  before do
    @orig_stdout = $stdout
    $stdout = StringIO.new
  end

  after do
    $stdout = @orig_stdout
  end

  it "returns the java options from the chorus properties jruby style" do
    any_instance_of(ChorusConfig) do |config|
      stub(config).[]('java_options') { "-server -Xmx1024m -XX:MaxPermSize=128m" }
    end
    load script_path

    output.should include "-J-Xmx1024m"
    output.should include "-J-XX:MaxPermSize=128m"
  end

  it "does not include the xms property" do
    any_instance_of(ChorusConfig) do |config|
      stub(config).[]('java_options') { "-Xms512m" }
    end
    load script_path

    output.should_not include "Xms"
  end

  it "correctly converts server property" do
    any_instance_of(ChorusConfig) do |config|
      stub(config).[]('java_options') { "-server -Xmx1024m -Xms512m" }
    end
    load script_path

    output.should include "--server"
  end

  it "correctly converts client property" do
    any_instance_of(ChorusConfig) do |config|
      stub(config).[]('java_options') { "-client -Xmx1024m -Xms512m" }
    end
    load script_path

    output.should include "--client"
  end

  def output
    $stdout.string
  end
end