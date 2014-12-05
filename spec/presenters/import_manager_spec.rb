require 'spec_helper'

describe ImportManager do
  let(:import_manager) { ImportManager.new(import) }

  describe "#schema_or_sandbox" do
    context "with a workspace_import" do
      let(:import) { imports(:one) }

      it "returns the workspace sandbox" do
        import_manager.schema.should == import.workspace.sandbox
      end
    end

    context "with a schema import" do
      let(:import) { imports(:oracle) }

      it "returns the schema" do
        import_manager.schema.should == import.schema
      end
    end
  end

  describe "#using_pipe?" do
    let(:import) { imports(:csv) }

    it "returns false for csv imports" do
      import_manager.using_pipe?.should be_false
    end
  end
end