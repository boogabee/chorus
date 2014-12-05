require 'spec_helper'

describe EnumeratorIO do
  let(:test_string) { 'abcd' }
  let(:enum) { test_string.to_enum(:each_char) }
  let(:io) { EnumeratorIO.new(enum) }

  describe '#read' do
    it 'returns each value in the enumerator' do
      test_string.each_char do |char|
        io.read(1).should == char
      end
    end

    it 'does not raise StopIteration when end of enumerator is reached' do
      expect {
        5.times {io.read(1)}
      }.not_to raise_error
    end

    it 'returns nil when reading past the length of the enumerator' do
      4.times {io.read(1)}
      io.read(1).should be_nil
    end
  end
end