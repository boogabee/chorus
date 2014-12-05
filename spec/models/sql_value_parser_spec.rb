require 'spec_helper'

describe SqlValueParser do
  let(:result_set) { Object.new }
  let(:parser) { SqlValueParser.new(result_set) }
  let(:column_type) { "hi" }

  describe "string_value" do
    subject { parser.string_value(0) }

    before do
      meta_data = Object.new
      stub(result_set).meta_data { meta_data }
      stub(meta_data).column_type_name(1) { column_type }
      stub(result_set).get_string(1) { string_result }
    end

    let(:string_result) { 'yo' }

    it { should == 'yo' }

    context "when the string comes back nil" do
      let(:string_result) { nil }
      it { should == "" }

      context "with a nil_value override" do
        let(:parser) { SqlValueParser.new(result_set, :nil_value => 'hows it going') }

        it { should == 'hows it going' }
      end
    end

    context "for float8 values" do
      let(:column_type) { "float8" }

      it "parses them correctly" do
        value_obj = Object.new
        stub(result_set).get_object(1) { value_obj }
        subject.should == value_obj.to_s
      end
    end
  end
end