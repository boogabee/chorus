require 'minimal_spec_helper'
require 'stringio'
require_relative '../../app/models/chorus_config'

describe "get_chorus_env_params" do

  let(:root_path) { File.expand_path('../../..', __FILE__) }
  let(:postgres_script_path) { File.expand_path('../../../packaging/get_postgres_port.rb', __FILE__) }
  let(:solr_script_path) { File.expand_path('../../../packaging/get_solr_port.rb', __FILE__) }
  let(:java_options_script_path) { File.expand_path('../../../packaging/get_full_java_options.rb', __FILE__) }
  let(:java_options_without_xms_script_path) { File.expand_path('../../../packaging/get_java_options_without_xms.rb', __FILE__) }
  let(:jruby_options_script_path) { File.expand_path('../../../packaging/get_jruby_options.rb', __FILE__) }
  let(:script_path) { File.expand_path('../../../packaging/get_chorus_env_params.rb', __FILE__) }
  let(:chorus_config) { ChorusConfig.new(root_path) }

  before do
    @orig_stdout = $stdout
    $stdout = StringIO.new
  end

  after do
    $stdout = @orig_stdout
  end

  it "returns the postgres port, solr port, java options, java options without xms, and jruby options" do
    postgres_port = get_script_output postgres_script_path
    solr_port = get_script_output solr_script_path
    java_options = get_script_output java_options_script_path
    java_options_without_xmx = get_script_output java_options_without_xms_script_path
    jruby_options = get_script_output jruby_options_script_path
    load script_path
    output.should include %Q(POSTGRES_PORT="#{postgres_port}")
    output.should include %Q(SOLR_PORT="#{solr_port}")
    output.should include %Q(CHORUS_JAVA_OPTIONS="#{java_options}")
    output.should include %Q(CHORUS_JAVA_OPTIONS_WITHOUT_XMS="#{java_options_without_xmx}")
    output.should include %Q(JRUBY_OPTS="#{jruby_options}")
  end

  def get_script_output(script)
    load script
    script_output = output
    $stdout = StringIO.new
    script_output
  end

  def output
    $stdout.string
  end
end