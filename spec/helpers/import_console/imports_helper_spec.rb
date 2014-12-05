require "spec_helper"

class DummyClass
  include ImportConsole::ImportsHelper
end

describe ImportConsole::ImportsHelper do
  let(:dummy) { DummyClass.new }

  describe "linking to tables" do

    context "when passing in a workspace" do
      let(:workspace) { workspaces(:public) }

      context "when the dataset is a chorus view" do
        let(:dataset) { datasets(:chorus_view) }

        it "includes chorus_views in the url" do
          dummy.link_to_workspace_table(workspace, dataset).should include("chorus_views")
        end
      end

      context "when the dataset is not a chorus view" do
        let(:dataset) { datasets(:table) }

        it "includes datasets in the url" do
          dummy.link_to_workspace_table(workspace, dataset).should include("datasets")
        end
      end
    end

    context "when passing in a schema" do
      let (:schema) { schemas(:public) }
      let (:dataset) { datasets(:table) }

      it "returns an URL to the dataset without schema/workspace in it" do
        dummy.link_to_table(dataset).should == "/#/datasets/#{dataset.id}"
      end
    end
  end

  describe "#link_to_destination" do
    let(:import_manager) { ImportManager.new(import) }

    before do
      stub(dummy).table_description(anything, import.to_table) { "a table description" }
      stub(dummy).link_to("a table description", anything) { "a_table_link" }
      stub.proxy(import_manager).schema_or_sandbox do |schema_or_sandbox|
        stub.proxy(schema_or_sandbox).datasets do |datasets|
          stub(datasets).find_by_name(import.to_table) { dataset }
        end
      end
    end

    context "when passing a workspace" do
      let(:import) { imports(:one) }

      context "if a destination table is present" do
        let (:dataset) { datasets(:table) }

        it "returns the correct link" do
          dummy.link_to_destination(import_manager).should == "a_table_link"
        end
      end

      context "if a destination table is not present" do
        let(:dataset) { nil }

        it "returns the description" do
          dummy.link_to_destination(import_manager).should == "a table description"
        end
      end
    end

    context "when passing a schema" do
      let(:import) { imports(:oracle) }

      context "if a destination table is present" do
        let (:dataset) { datasets(:table) }

        it "returns the correct link" do
          dummy.link_to_destination(import_manager).should == "a_table_link"
        end
      end

      context "if a destination table is not present" do
        let(:dataset) { nil }

        it "returns the description" do
          dummy.link_to_destination(import_manager).should == "a table description"
        end
      end
    end
  end

  describe "#table_description" do
    context "when the schema belongs to a database" do
      it "returns a description consisting of database, schema and table name" do
        table_description(schemas(:default), "gpdb_table").should == "default.default.gpdb_table"
      end
    end

    context "when the schema belong to a database" do
      it "omits the database" do
        table_description(schemas(:oracle), "oracle_table").should == "oracle.oracle_table"
      end
    end

    context "when the schema is nil" do
      it "returns the empty string" do
        table_description(nil, "anything").should == ""
      end
    end
  end
end