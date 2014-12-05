require 'spec_helper'

describe Kaggle::UserPresenter, :type => :view do
  include KaggleSpecHelpers

  let(:kaggle_user) { kaggle_users_api_result.first }
  let(:presenter) { Kaggle::UserPresenter.new(kaggle_user, view) }

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    it "should include the correct keys" do
      hash.should have_key('id')
      hash.should have_key('location')
      hash.should have_key('rank')
      hash.should have_key('points')
      hash.should have_key('number_of_entered_competitions')
      hash.should have_key('gravatar_url')
      hash.should have_key('full_name')
      hash.should have_key('favorite_technique')
      hash.should have_key('favorite_software')
      hash['past_competition_types'].should be_a(Array)
    end
  end
end