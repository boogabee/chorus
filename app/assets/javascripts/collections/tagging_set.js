chorus.collections.TaggingSet = chorus.collections.Base.extend({
    urlTemplate: 'taggings?entity_id={{entity.id}}&entity_type={{entity.entityType}}',
    model: chorus.models.Tag,
    constructorName: "TaggingSet",

    containsTag: function(tagName) {
        return this.any(function(tag) {
            return tag.matches(tagName);
        });
    },

    _tagNames: function() {
        return this.map(function(tag) {
            return tag.name();
        });
    },

    add: function(models, options){
        models = _.isArray(models) ? models.slice() : [models];
        models = _.reject(models, function(model){
            var name = model instanceof chorus.models.Base ? model.get('name') : model.name;
            return this.containsTag(name);
        }, this);
        this._super('add', [models, options]);
    }
});