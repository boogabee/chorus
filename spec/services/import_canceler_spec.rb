require 'spec_helper'

describe ImportCanceler do
  before do
    any_instance_of(Import) do |import|
      stub(import).table_exists? { false }
    end
  end

  describe "imports_awaiting_cancel" do
    let!(:started_canceled_import) { FactoryGirl.create(:import, {:started_at => Time.now, :canceled_at => Time.now}) }
    let!(:unstarted_canceled_import) { FactoryGirl.create(:import, {:started_at => nil, :canceled_at => Time.now}) }
    let!(:started_uncanceled_import) { FactoryGirl.create(:import, {:started_at => Time.now}) }
    let!(:unstarted_import) { FactoryGirl.create(:import, {:started_at => nil}) }
    let!(:successful_import) { FactoryGirl.create(:import, {:started_at => Time.now, :finished_at => Time.now, :success => true, :canceled_at => Time.now}) }
    let!(:failed_import) { FactoryGirl.create(:import, {:started_at => Time.now, :finished_at => Time.now, :success => false, :canceled_at => Time.now}) }

    it "finds only the imports that are waiting to be canceled, are started, and are not already failed or succeeded" do
      subject.imports_awaiting_cancel.size.should == 1
      subject.imports_awaiting_cancel.should == [started_canceled_import]
    end
  end

  describe 'cancel_imports' do
    before do
      5.times { FactoryGirl.create(:import, {:started_at => Time.now, :canceled_at => Time.now}) }
    end

    it "sends 'cancel' to imports that have been started & marked for cancellation" do
      any_instance_of(Import) { |import| stub(import).cancel.with_any_args }
      imports_awaiting_cancel = subject.imports_awaiting_cancel
      stub(subject).imports_awaiting_cancel { imports_awaiting_cancel }

      imports_awaiting_cancel.each { |import| mock(import).cancel(false) }
      subject.cancel_imports
    end
  end

  describe '.run' do
    let(:canceler) { Object.new }

    it 'creates a new instance and calls run on it' do
      mock(ImportCanceler).new { canceler }
      mock(canceler).run

      ImportCanceler.run
    end
  end
end