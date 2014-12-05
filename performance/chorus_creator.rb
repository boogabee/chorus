require 'rubygems'
require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'
require 'spec/integration/helpers/cleditor_helpers'
require 'spec/integration/helpers/modal_helpers'
require 'spec/integration/helpers/login_helpers'

Capybara.run_server = false
Capybara.default_driver = :poltergeist
Capybara.app_host = 'http://chorus-load-test:8080'

module ChorusCreator
  include Capybara::DSL
  include LoginHelpers
  include CleditorHelpers
  extend self

  LoginHelpers::WEBPATH = {'login_route' => "/"}

  def username
    "chorusadmin"
    #CSV.read('load_test_users.csv').first[2]
  end

  def create_something
    within '.activities' do
      links = page.all('a.comment')
      target = links.sample
      target.click
    end

    within_modal(30) do
      set_cleditor_value("body", "This is adding a Comment")
      click_on "Add Comment"
    end

    wait_for_ajax


    #Create a comment on an activity
    #Post a new note/insight on an entity
    #Promote a note to insight
    #Publish an insight
    #Changes the body of a note
    #Attach a visualization to a note
    #Attach the contents of a file to a note

    #Duplicate Chorus View

    #Copy a workfile to a workspace
    #Create a new workfile in a workspace
    #Create a draft of a workfile for the current user
    #Create a new version of a workfile

    #Create a workspace

    # stuff that isn't that different
    #Create a Chorus View
    #Update a Chorus View

    # alter gpdb or hadoop
    #Create external table from CSV file on hadoop
    #Complete import of a CSV file
    #Convert a Chorus View to Database view
    #Import an existing dataset into a workspace, or create an import for a dataset

    page.evaluate_script('window.history.back()')
    wait_for_ajax
  end

  def run
    login(username, "secret")
    sleep(5)
    create_something
  end

  private

  def wait_for_ajax(timeout = 30)
    page.wait_until(timeout) do
      page.evaluate_script 'jQuery.active == 0'
    end
  end

  def set_cleditor_value(name, value)
    wait_until { page.find("textarea[name=#{name}]") }
    page.execute_script("$('textarea[name=#{name}]').val('#{value}');")
    page.execute_script("$('textarea[name=#{name}]').cleditor()[0].updateFrame();")
  end
end
