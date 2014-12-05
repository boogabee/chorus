chorus.models.TaggingsUpdater = chorus.models.Base.extend({
    urlTemplate: 'taggings', // backbone requires something here
    constructorName: "TaggingsUpdater",

    updateTags: function(options) {
        var tagging = new this.Taggings(_.extend({taggables: this.getTaggables()}, options));
        this.listenTo(tagging, "saved", this.taggingsSaved);
        this.listenTo(tagging, "saveFailed", this.taggingsSaveFailed);
        this.pushTaggingOntoQueue(tagging);
    },

    Taggings: chorus.models.Base.extend({
        urlTemplate: "taggings",

        initialize: function() {
            var method = this.get('add') ? 'add' : 'remove';
            var tag = this.get('add') || this.get('remove');
            this.set(method, tag.name());
        }
    }),

    pushTaggingOntoQueue: function(tagging) {
        // ensure that only one save happens at a time
        this.queue = this.queue || [];

        this.queue.push(tagging);
        if(this.queue.length === 1) {
            tagging.save();
        }
    },

    saveNextTaggingFromQueue: function() {
        this.queue.shift(); // note that the last tagging has finished saving by removing it
        if(this.queue.length > 0) {
            this.queue[0].save(); // start saving the next tagging
        }
    },

    getTaggables: function() {
        return this.get("collection").map(function(model) {
            return {
                entityId: model.id,
                entityType: model.get('entityType')
            };
        });
    },

    taggingsSaved: function() {
        this.saveNextTaggingFromQueue();
        this.trigger("updated");
    },

    taggingsSaveFailed: function(saverWithServerError) {
        var tagName = this.queue[0].get('add') || this.queue[0].get('remove');
        chorus.toast("tag_update_failed", {tagName: tagName, toastOpts: {type: "error"}});
        this.queue = [];
        this.trigger("updateFailed", saverWithServerError);
    }
});