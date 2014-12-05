require 'csv'

class CsvFilePresenter < Presenter
  def to_hash
    {
        :id => model.id,
        :contents => contents,
        :entity_type => model.entity_type_name
    }
  rescue => e
    model.errors.add(:contents, :FILE_INVALID)
    raise ActiveRecord::RecordInvalid.new(model)
  end

  def contents

    begin
      result = []
      CSV.foreach(model.contents.path, :col_sep=>",") do |row|
        break if result.length > 99
        result << row.to_csv
      end
    rescue CSV::MalformedCSVError => e
      result = []
      File.open(model.contents.path).each do |row|
        break if result.length > 99
        result << row
      end
    end

    result
  end

  def complete_json?
    true
  end
end