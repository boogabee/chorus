class AlpineWorkfileValidator < ActiveModel::Validator
  def validate(record)
    ensure_no_chorus_views(record)
  end

  def ensure_no_chorus_views(record)
    record.errors[:datasets] << :chorus_view_selected if record.datasets.map(&:type).include?("ChorusView")
  end
end
