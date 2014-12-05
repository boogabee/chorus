desc 'Run phantom against Jasmine for all specs, once'
task :phantom do
    `which phantomjs`
    raise "Could not find phantomjs on your path" unless $?.success?
    port = ENV['JASMINE_PORT'] || 8888
    sh "phantomjs #{File.dirname(__FILE__)}/../../spec/run-phantom-jasmine.js #{port} nocolor #{ENV['filter']}"
end
