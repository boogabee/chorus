class Presenter
  def self.present(model_or_collection, view_context, options={})
    if model_or_collection.is_a?(ActiveRecord::Relation) || model_or_collection.is_a?(Enumerable)
      present_collection(model_or_collection, view_context, options)
    else
      present_model(model_or_collection, view_context, options)
    end
  end

  def self.present_model(model, view_context, options)
    presenter_class = get_presenter_class(model, options)
    presenter_class.new(model, view_context, options).presentation_hash
  end

  def self.present_collection(collection, view_context, options)
    collection.map { |model| present_model(model, view_context, options.dup) }
  end

  def present(model, options={})
    options = options.dup
    self.class.present(model, @view_context, options)
  end

  def initialize(model, view_context, options={})
    @options = options
    @model = model
    @view_context = view_context
  end

  delegate :sanitize, :to => :@view_context

  attr_reader :model, :options

  def complete_json?
    false
  end

  def complete_json
    complete_json? ? {:complete_json => true} : {}
  end

  def presentation_hash
    return forbidden_hash if options[:forbidden]

    hash = to_hash
    hash.merge(complete_json) if hash
  end

  def forbidden_hash
    {}
  end

  private

  def self.get_presenter_class(model, options)
    return options.delete(:presenter_class).to_s.constantize if options[:presenter_class]

    if model.is_a? Paperclip::Attachment
      ImagePresenter
    else
      model.class.respond_to?(:presenter_class) ? model.class.presenter_class : "#{model.class.name}Presenter".constantize
    end
  end

  def rendering_activities?
    @options[:activity_stream]
  end

  def succinct?
    @options[:succinct]
  end
end
