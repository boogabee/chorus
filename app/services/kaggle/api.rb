require "net/https"
require "uri"
require 'json'

module Kaggle
  module API
    MessageFailed = Class.new(StandardError)
    NotReachable = Class.new(StandardError)

    API_URL = "https://www.kaggle.com/connect/chorus-beta/"

    def self.send_message(params)
      return unless self.enabled?
      decoded_response = send_to_kaggle(params)
      result_status = decoded_response["status"]

      if result_status != 200 || !decoded_response['failed'].empty?
        raise MessageFailed.new("Could not send message to users")
      end

      true
    end

    def self.users(options = {})
      self.fetch_users.select {|user| search_through_filter(user, options[:filters])}
    end

    def self.enabled?
      config = ChorusConfig.instance
      config['kaggle'] && (config['kaggle']['enabled'] == true)
    end

    private

    def self.fetch_users
      if self.enabled?
        uri = uri_for("directory")
        http = connection_for(uri)

        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)

        JSON.parse(response.body)["users"].map do |user_data|
          Kaggle::User.new(user_data)
        end
      else
        JSON.parse(File.read(Rails.root.join('demo_data', 'kaggleSearchResults.json').to_s))["users"].map do |user_data|
          Kaggle::User.new(user_data)
        end
      end

    rescue
      raise Kaggle::API::NotReachable.new("Unable to get the list of Kaggle Contributors")
    end

    private

    def self.send_to_kaggle(post_params)
      uri = uri_for("message")
      http = connection_for(uri)

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(post_params)
      response = http.request(request)

      JSON.parse(response.body)
    rescue Timeout::Error
      raise MessageFailed.new("Could not connect to the Kaggle server")
    rescue => e
      raise MessageFailed.new("Error: " + e.message)
    end

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

    def self.connection_for(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.ca_file = Rails.root.join('config/certs/sf-class2-root.pem').to_s

      http
    end

    def self.uri_for(endpoint)
      URI.parse(API_URL + endpoint + "?apiKey=#{self.api_key}")
    end

    def self.api_key
      ChorusConfig.instance['kaggle']['api_key']
    end
  end
end
