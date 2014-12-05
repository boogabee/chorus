class ImagePresenter < Presenter

  def to_hash
    {
        :original => model.url(:original),
        :icon => model.url(:icon),
        :entity_type => 'image'
    }
  end

  def complete_json?
    true
  end
end

