shared_examples_for 'a soft deletable model' do
  before do
    any_instance_of(GreenplumConnection) do |data_source|
      stub(data_source).running? { false }
    end
  end

  context 'before deletion' do
    it 'has a nil deleted_at' do
      model.deleted_at.should be_nil
    end
  end

  context 'after deletion' do
    before do
      model.destroy
    end

    it "should still exist in the database" do
      expect { model.class.unscoped.find(model.id) }.not_to raise_error
    end

    it "sets deleted_at" do
      model.deleted_at.should_not be_nil
    end
  end

  if described_class.searchable?
    context 'when the model is searchable' do
      it 'does not index when deleted' do
        dont_allow(model).solr_index
        model.destroy
      end
    end
  end
end