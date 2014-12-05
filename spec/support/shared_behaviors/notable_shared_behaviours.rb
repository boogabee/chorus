shared_examples_for "a notable model" do
  it { should have_many :notes }

  it "includes the note" do
    model.notes.should include note
  end

  context "when it is destroyed" do
    before do
      any_instance_of(GreenplumConnection) do |data_source|
        stub(data_source).running? { false }
      end
    end

    it "removes the associated notes from the Solr index" do
      stub(Sunspot).remove
      mock(Sunspot).remove(satisfy {|arg|
        arg.id == note.id and arg.class == note.class
      })
      model.destroy
    end
  end
end