require 'minimal_spec_helper'
require_relative "../../packaging/install/chorus_executor"
require 'fakefs/spec_helpers'

describe ChorusExecutor do
  describe "constructor" do
    context "when the logger passed in is nil" do
      it "raises an exception" do
        expect {
          ChorusExecutor.new(:logger => nil)
        }.to raise_error(InstallerErrors::InstallationFailed, /Logger must be set/)
      end
    end
  end

  context "after construction" do
    let(:executor) { ChorusExecutor.new(:logger => logger, :debug => debug) }
    let(:logger) { Object.new }
    let(:destination_path) { "fooPath" }
    let(:version) { "extra_crispy" }
    let(:release_path) { "fooPath/releases/extra_crispy" }
    let(:postgres_bin_path) { release_path }
    let(:prefix) { "PATH=#{postgres_bin_path}/postgres/bin:$PATH &&" }
    let(:full_command) { "#{prefix} #{command}" }
    let(:command_success) { true }
    let(:command_times) { 1 }
    let(:debug) { false }
    let(:alpine_env) { "ALPINE_HOME=#{destination_path}/alpine-current ALPINE_DATA_REPOSITORY=#{destination_path}/shared/ALPINE_DATA_REPOSITORY" }

    before do
      executor.destination_path = destination_path
      executor.version = version
      mock(logger).debug(full_command).times(command_times)
      mock(logger).capture_output(full_command).times(command_times) { command_success }
    end

    describe "#exec" do
      let(:command) { "hello" }

      describe "with a valid command" do
        it "executes the command with the correct path" do
          executor.exec(command)
        end
      end

      describe "when the command fails" do
        let(:command_success) { false }
        it "raises command failed" do
          expect {
            executor.exec(command)
          }.to raise_error(InstallerErrors::CommandFailed)
        end
      end

      describe "when given a postgres bin path" do
        let(:postgres_bin_path) { "/somewhere/else" }
        it "uses that as the postgres bin path" do
          executor.exec(command, postgres_bin_path)
        end
      end
    end

    describe "#rake" do
      let(:rake_task) { "hahaha" }
      let(:command) { "cd #{release_path} && RAILS_ENV=production bin/ruby -S bin/rake #{rake_task}" }

      it "should execute correctly" do
        executor.rake rake_task
      end

      context "when debugging" do
        let(:debug) { true }
        let(:command) { "cd #{release_path} && RAILS_ENV=production bin/ruby -S bin/rake #{rake_task} --trace" }

        it "should append --trace" do
          executor.rake rake_task
        end
      end
    end

    describe "#initdb" do
      let(:data_path) { "weee" }
      let(:database_user) { "some_user_guy" }
      let(:command) { "initdb --locale=en_US.UTF-8 -D #{data_path}/db --auth=md5 --pwfile=#{release_path}/postgres/pwfile --username=#{database_user}" }

      it "should execute the correct initdb command" do
        executor.initdb data_path, database_user
      end
    end

    describe "#start_postgres" do
      let(:command) { "CHORUS_HOME=#{release_path} #{alpine_env} #{release_path}/packaging/chorus_control.sh start postgres" }
      before do
        mock(logger).log("starting postgres...")
      end

      it "should work" do
        executor.start_postgres
      end
    end

    describe "#start_chorus" do
      let(:command) { "CHORUS_HOME=#{release_path} #{alpine_env} #{release_path}/packaging/chorus_control.sh start" }

      it "should work" do
        executor.start_chorus
      end
    end

    describe "#stop_postgres" do
      before do
        stub(File).directory?("#{release_path}/postgres") { postgres_extracted }
      end

      let(:command) { "CHORUS_HOME=#{release_path} #{alpine_env} #{release_path}/packaging/chorus_control.sh stop postgres" }

      context "when postgres has been extracted" do
        let(:postgres_extracted) { true }
        before do
          mock(logger).log("stopping postgres...")
        end

        it "should work" do
          executor.stop_postgres
        end
      end

      context "when postgres has not yet been extracted" do
        let(:postgres_extracted) { false }
        let(:command_times) { 0 } # don't actually run the command

        before do
          dont_allow(logger).log("stopping postgres...")
        end

        it "should do nothing" do
          executor.stop_postgres
        end
      end
    end

    describe "#extract_postgres" do
      let(:package_name) { 'postgres-blahblah.tar.gz' }
      let(:command) { "tar xzf #{release_path}/packaging/postgres/#{package_name} -C #{release_path}" }

      it "should work" do
        executor.extract_postgres package_name
      end
    end

    describe "#start_previous_release" do
      let(:postgres_bin_path) { "#{destination_path}/current" }
      let(:command) { "CHORUS_HOME=#{destination_path}/current #{alpine_env} #{destination_path}/chorus_control.sh start" }

      it "should work" do
        executor.start_previous_release
      end
    end

    describe "#stop_previous_release" do
      let(:postgres_bin_path) { "#{destination_path}/current" }
      let(:command) { "CHORUS_HOME=#{destination_path}/current #{alpine_env} #{destination_path}/chorus_control.sh stop" }

      it "should work" do
        executor.stop_previous_release
      end
    end
  end
end
