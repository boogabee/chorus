class TableauWorkbook
  include ActiveModel::Validations

  attr_accessor :name
  def initialize(hsh); end

  def server_url; end

  def is_chorus_view?; end

  def self.strip_trailing_semicolon(str); end

  def save; end

  def destroy; end

  def image_url; end
end
