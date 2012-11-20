require "net/https"
require "uri"
require 'json'

module Kaggle
  module API
    MessageFailed = Class.new(StandardError)

    API_URL = "https://www.kaggle.com/connect/chorus-beta/message"

    def self.send_message(params)
      decoded_response = send_to_kaggle(params)
      result_status = decoded_response["status"]

      if result_status != 200
        raise MessageFailed.new("Could not send message to user(s): " + decoded_response['details'])
      end

      if !decoded_response['failed'].empty?
        raise MessageFailed.new("Could not send message to user(s): " + decoded_response['failed'].join(','))
      end

      true
    end

    def self.users(options = {})
      users = JSON.parse(File.read(Rails.root + "kaggleSearchResults.json")).collect {|data| Kaggle::User.new(data)}
      users.select {|user| search_through_filter(user, options[:filters])}
    end

    private

    def self.search_through_filter(user, filters)
      return_val = true
      return return_val if filters.nil?
      filters.each { |filter|
        key, comparator, value = filter.split("|")
        next unless value
        value = URI.decode(value)
        value = value.to_i if value.try(:to_i).to_s == value.to_s
        case comparator
          when 'greater'
            return_val = return_val && (user[key] > value)
          when 'less'
            return_val = return_val && (user[key] < value)
          when 'includes'
            return_val = return_val && (user[key] || '').downcase.include?(value.to_s.downcase)
          else #'equal'
            if key == 'past_competition_types'
              return_val = return_val && (user[key].map(&:downcase).include?(value.downcase))
            else
              return_val = return_val && (user[key] == value)
            end
        end
      }
      return_val
    end

    def self.send_to_kaggle(post_params)
      uri = URI.parse(API_URL)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.ca_file = Rails.root.join('config/certs/sf-class2-root.pem').to_s

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(post_params)
      response = http.request(request)

      JSON.parse(response.body)
    rescue Timeout::Error
      raise MessageFailed.new("Could not connect to the Kaggle server")
    rescue Exception => e
      raise MessageFailed.new("Error: " + e.message)
    end
  end
end
