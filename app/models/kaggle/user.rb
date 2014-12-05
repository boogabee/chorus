module Kaggle
  class User
    def initialize(attributes)
      @data = attributes
    end

    def number_of_entered_competitions
      @data["PastCompetitions"].length
    end

    def [](method_name)
      return @data[method_name] unless METHOD_MAP.stringify_keys.keys.include?(method_name) || method_name == 'number_of_entered_competitions'
      send(method_name.to_sym)
    end

    METHOD_MAP = {
        :id => :KaggleId,
        :location => :Location,
        :rank  => :KaggleRank,
        :points => :KagglePoints,
        :gravatar_url => :Gravatar,
        :full_name => :LegalName,
        :past_competition_types => :PastCompetitionTypes,
        :favorite_technique => :FavoriteTechnique,
        :favorite_software => :FavoriteSoftware
    }

    METHOD_MAP.each do |key, value|
      define_method(key) do
        @data[value.to_s]
      end
    end
  end
end