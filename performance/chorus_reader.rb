require 'rubygems'
require 'capybara'
require 'capybara/poltergeist'
require 'capybara/dsl'
require 'spec/integration/helpers/login_helpers'
require 'csv'

Capybara.run_server = false
Capybara.default_driver = :poltergeist
#Capybara.default_driver = :selenium
Capybara.app_host = 'http://chorus-load-test:8080'

module ChorusReader
  include Capybara::DSL
  include LoginHelpers
  extend self

  LoginHelpers::WEBPATH = {'login_route' => "/"}

  def username
    CSV.read('load-test-users.csv').sample[2]
  end

  def read_event
    within '.activities' do
      links = all('a', :visible => true).reject {|a| a['href'] == '#' }
      target = links.sample
      target.click
      wait_for_ajax
    end

    evaluate_script('window.history.back()')
    wait_for_ajax
  rescue => e
    raise e unless e.class.to_s =~ /Capybara/
  end

  def run(count = 10)
    login username, "changeme"
    count.times do
      sleep(2)
      read_event
    end
  end

  def run_test(length = 8 * 60 * 60, max = 200)
    threads = []
    start_time = Time.now

    while ((start_time + length) > Time.now)
      thread_limit = (Time.now - start_time) / length * max

      break if thread_limit >= 20

      puts "thread limit is #{thread_limit}"

      if threads.count < thread_limit || threads.count == 0
        threads << Thread.new {
          system "rspec /Users/pivotal/workspace/chorusrails/spec/performance/chorus_reader_spec.rb --example 'ChorusReader runs for 5 minutes'"
        }
        threads.last.run
      else
        threads.shift.join
      end
    end

    threads.map &:join
  end

  private

  def wait_for_ajax(timeout = 30)
    page.wait_until(timeout) do
      page.evaluate_script 'jQuery.active == 0'
    end
  end
end
