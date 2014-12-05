require 'timecop'

shared_examples_for 'something that can go stale' do
  let(:model) { nil }
  let(:bread) { model }

  describe '#stale?' do
    context 'when #stale_at is set' do
      before { bread.stale_at = 1.hour.ago }

      it('returns true') { bread.should be_stale }
    end

    context 'when #stale_at is not set' do
      before { bread.stale_at = nil }

      it('returns false') { bread.should_not be_stale }
    end
  end

  describe '#mark_stale!' do
    it 'does not validate' do
      stub(bread).valid? { false }
      bread.mark_stale!
      bread.should be_stale
    end

    it 'sets stale_at to current time' do
      now = Time.zone.now

      Timecop.freeze(now) do
        bread.mark_stale!
        bread.stale_at.to_i.should == now.to_i
      end
    end

    it 'does not change stale_at when already stale' do
      bread.mark_stale!

      expect do
        bread.mark_stale!
      end.not_to change(bread, :stale_at)
    end
  end
end