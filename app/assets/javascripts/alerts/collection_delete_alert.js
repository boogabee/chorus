chorus.alerts.CollectionDelete = chorus.alerts.Confirm.extend({
    events: _.extend({}, chorus.alerts.Base.prototype.events, {
        "click button.submit": "deleteCollection"
    }),
    constructorName: "CollectionDelete",
    focusSelector: "button.cancel",
    additionalClass: "error",
    persistent: true, //here for documentation, doesn't actually do anything as we've overwritten bindCallbacks

    deleteCollection: function(e) {
        e.preventDefault();
        this.collection.destroy();
        this.collectionDeleted();
    },

    deleteMessageParams: $.noop,

    collectionDeleted: function() {
        this.closeModal();
        chorus.toast(this.deleteMessage, this.deleteMessageParams());
        chorus.PageEvents.trigger(this.collection.entityType + ":deleted", this.collection);
        if (this.redirectUrl) {
            chorus.router.navigate(this.redirectUrl);
        }
    }
});