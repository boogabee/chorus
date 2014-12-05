module Kaggle
  class UsersController < ApplicationController
    def index
      begin
        users = Kaggle::API.users(:filters => params[:filters])
        users.sort! { |user1, user2| user1['rank'] <=> user2['rank'] }
        present users
      rescue Kaggle::API::NotReachable
        present_errors({:record => :KAGGLE_API_UNREACHABLE}, :status => :unprocessable_entity)
      end
    end
  end
end