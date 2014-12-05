require 'spec_helper'

describe Properties do
  describe '.load_file' do
    let(:translation_string) {str = <<-EOF
      quux=Non-nested
      test.foo=Bar
      test.bar.baz=Stuff
      types.number=42
      types.negative=-7
      types.decimal=-7.5
      types.true=true
      types.false=false
      types.array=[\\
        An,\\
        array,\\
        of,\\
        strings\\
      ]

      #I am a comment
      #comment= comment_value
      multiline=\\
          line2\\
          line3
      value_with_equal_sign=1+1=2
      EOF

      str << "whitespace = a_value  "
      str
    }

    let(:hash) {
      stub(File).read('some_file_name') { translation_string }
      Properties.load_file('some_file_name')
    }

    it 'returns non-nested string' do
      hash["quux"].should == "Non-nested"
    end

    it "handles nested keys" do
      hash["test"]["foo"].should == 'Bar'
      hash["test"]["bar"]["baz"].should == 'Stuff'
    end

    it "strips whitespace" do
      hash["whitespace"].should == "a_value"
    end

    it "handles comments, and blank lines" do
      topLevelKeys = ['quux', 'test', 'multiline', 'value_with_equal_sign', 'whitespace', 'types']

      hash.keys.should =~ topLevelKeys
    end

    it "handles equal signs in the value" do
      hash["value_with_equal_sign"].should == '1+1=2'
    end

    it "handles multi line translations" do
      hash["multiline"].should include('line2')
      hash["multiline"].should include('line3')
      hash["multiline"].should_not include('\\')
    end

    describe "type casting" do
      it "handles numbers" do
        hash["types"]["number"].should == 42
        hash["types"]["number"].to_s.should == "42"
        hash["types"]["negative"].should == -7
        hash["types"]["decimal"].should == -7.5
      end

      it "handles booleans" do
        hash["types"]["true"].should == true
        hash["types"]["false"].should == false
      end

      it "handles arrays" do
        hash["types"]["array"].should =~ %w(An array of strings)
      end
    end

  end

  describe '.dump_file' do
    let(:hash) { {
      'test1' => {'value1' => 10},
      'test2' => 20
    } }
    let(:destination) { 'spec/lib/shared/converted.properties' }

    it 'writes to the properties file' do
      Properties.dump_file(hash, destination)
      lines = File.read(destination).split("\n")
      lines[0].should == "test1.value1= 10"
      lines[1].should == "test2= 20"
    end

    after do
      File.delete(destination)
    end
  end
end