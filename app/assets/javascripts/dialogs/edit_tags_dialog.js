chorus.dialogs.EditTags = chorus.dialogs.Base.extend({
    constructorName: "EditTagsDialog",
    templateName: "edit_tags",
    title: t("edit_tags.title"),
    persistent: true,

    subviews: {
        ".tags_input": "tagsInput"
    },

    setup: function() {
        var tags = this.tags();
        this.listenTo(tags, "add", this.addTag);
        this.listenTo(tags, "remove", this.removeTag);
        this.listenTo(this.collection, "updateTagsFailed", this.saveFailed);
        this.tagsInput = new chorus.views.TagsInput({tags: tags, taggable: this.collection});
    },

    addTag: function(tag) {
        this.collection.each(function(model) {
            model.tags().add(tag);
        });
    },

    removeTag: function(tag) {
        this.collection.each(function(model) {
            var tagToRemove = model.tags().where({name: tag.name()});
            model.tags().remove(tagToRemove);
        });
    },

    tags: function() {
        if(!this._tags) {
            var tagNames = this.collection.map(function(model) {
                return _.invoke(model.tags().pluck("name"), "split", ',');
            });
            tagNames = _.uniq(_.flatten(tagNames));

            var tagsHash = _.map(tagNames, function(tagName) {
                return {name: tagName};
            });

            this._tags = new chorus.collections.TaggingSet(tagsHash);
        }
        return this._tags;
    },

    saveFailed: function(tags) {
        this.showErrors(tags);
        this.tagsInput.$el.addClass('hidden');
    },

    revealed: function() {
        this._super("revealed", arguments);
        $("#facebox").css("overflow", "visible");
        var self = this;
        setTimeout(function () {
            self.tagsInput.focusInput();
        }, 0);
    }
});