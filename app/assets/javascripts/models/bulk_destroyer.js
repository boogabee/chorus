chorus.models.BulkDestroyer = chorus.models.Base.extend({
    url: function(options) {
        return this.attributes.collection.url(options);
    },

    initialize: function() {
        this.bind("destroy", _.bind(function() {
            this.trigger("destroy");
        }, this.attributes.collection));
    },

    // backbone will not perform a destroy for objects it considers 'new'
    // (objects without an 'id'), so we need to force it to believe
    // this BulkDestroyer is not 'new'
    isNew: function () {
        return false;
    },

    destroy: function (options) {
        // backbone will not take any additional data for a 'destroy' call unless
        // it is forced into the options.data property, so we'll send along
        // our options in the 'data' property
        return this._super('destroy', [{data: JSON.stringify(this.underscoreKeys(options)), contentType: 'application/json'}]);
    },

    handleRequestFailure: function() {
        var collection = this.attributes.collection;
        collection.handleRequestFailure.apply(collection, arguments);
    }
});