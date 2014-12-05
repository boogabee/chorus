require 'spec_helper'

describe GnipDataSourcePresenter, :type => :view do
  let(:gnip_data_source) { gnip_data_sources(:default) }
  let(:user) { gnip_data_source.owner }
  let(:presenter) { GnipDataSourcePresenter.new(gnip_data_source, view, options) }
  let(:options) { {} }

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    it "includes the right keys" do
      hash.should have_key(:name)
      hash.should have_key(:stream_url)
      hash.should have_key(:id)
      hash.should have_key(:is_deleted)
      hash.should have_key(:owner)
      hash.should have_key(:description)
      hash.should have_key(:username)
      hash.should have_key(:tags)
      hash.should have_key(:state)

      hash[:entity_type].should == "gnip_data_source"
    end

    it "excludes the password" do
      hash.should_not have_key(:password)
    end

    it_behaves_like "activity stream data source presenter"
    it_behaves_like :succinct_data_source_presenter
  end
end
