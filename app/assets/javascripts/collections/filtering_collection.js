chorus.collections.FilteringCollection = chorus.collections.Base.extend({
    constructorName:"FilteringCollection",

    setup:function (args) {

        if(!this.attributes.collection) {
            throw "Must initialize FilteringCollection with a child collection";
        }
        if(args[0]) {
            throw "Must initialize FilteringCollection with null";
        }
        this.listenTo(this.attributes.collection, 'reset loaded', this.updateCollection);
        this.listenTo(this.attributes.collection, 'loaded', this.markLoaded);
        this.listenTo(this.attributes.collection, 'serverResponded', this.markResponded);
        this.updateCollection();
    },

    search:function (term) {
        this.attributes.filter = (term || "").toLowerCase();
        this.updateCollection();
        this.trigger('searched');
    },

    markLoaded: function () {
        this.loaded = true;
        this.trigger('loaded');
    },

    markResponded: function() {
        this.statusCode = this.attributes.collection.statusCode;
        this.trigger('serverResponded');
    },

    updateCollection: function () {
        this.reset(this.attributes.collection.select(_.bind(function (model) {
            return !this.attributes.filter || model.name().toLowerCase().indexOf(this.attributes.filter) >= 0;
        }, this)), {silent:true});
    },

    fetch: function () {
        this.attributes.collection.fetch.apply(this.attributes.collection, arguments);
    },

    fetchAll: function () {
        this.attributes.collection.fetchAll.apply(this.attributes.collection, arguments);
    },

    url: function () {
        return this.attributes.collection.url.apply(this.attributes.collection, arguments);
    },

    remove: function () {
        this._super('remove', arguments);
        return this.attributes.collection.remove.apply(this.attributes.collection, arguments);
    }
});