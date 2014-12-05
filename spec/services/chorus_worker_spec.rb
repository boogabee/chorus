require 'spec_helper'

describe "ChorusWorker" do
  describe "monkey patch to QC.log" do
    let(:timestamp) { 3.hours.ago }

    it "adds a timestamps to the data" do
      worker = ChorusWorker.new
      Timecop.freeze(timestamp) do
        stub(Scrolls).log # we disconnect QC from the database after each test, and that call isn't frozen (ignore it)
        mock(Scrolls).log(hash_including(:timestamp => timestamp.to_s, :data => "legit"))
        worker.log(:data => "legit")
      end
    end
  end

  describe "start" do
    it "starts the ImportCanceler" do
      QC.enqueue("Kernel.puts", 1)
      mock(ImportCanceler).run
      worker = ChorusWorker.new
      t = Thread.new { worker.start }
      worker.instance_variable_set(:@running, false)
      t.join
    end
  end
end