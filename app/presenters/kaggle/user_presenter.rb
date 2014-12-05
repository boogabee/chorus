module Kaggle
  class UserPresenter < Presenter
    def to_hash
      {
          'id' => model['id'],
          'location' => model['location'],
          'rank' => model['rank'],
          'points' => model['points'],
          'number_of_entered_competitions' => model['number_of_entered_competitions'],
          'gravatar_url' => model['gravatar_url'],
          'full_name' => model['full_name'],
          'favorite_technique' => model['favorite_technique'],
          'favorite_software' => model['favorite_software'],
          'past_competition_types' => model['past_competition_types']
      }
    end
  end
end