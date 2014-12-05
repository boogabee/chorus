require "performance/chorus_reader"

describe ChorusReader do
  it "runs quickly" do
    ChorusReader.run 1
  end

  it "runs for 5 minutes" do
    ChorusReader.run 5
  end

  it "runs a test" do
    ChorusReader.run_test
  end
end
