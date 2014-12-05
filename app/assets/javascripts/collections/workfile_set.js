chorus.collections.WorkfileSet = chorus.collections.LastFetchWins.include(
    chorus.Mixins.CollectionFetchingSearch
).extend({
    constructorName: "WorkfileSet",
    model: chorus.models.DynamicWorkfile,
    urlTemplate: "workspaces/{{workspaceId}}/workfiles",
    showUrlTemplate: "workspaces/{{workspaceId}}/workfiles",
    searchAttr: "namePattern",
    per_page: 20,

    urlParams: function() {
        return {
            namePattern: this.attributes.namePattern,
            fileType: this.attributes.fileType
        };
    },

    destroy: function() {
        var ids = _.pluck(this.models, 'id');
        new chorus.models.BulkDestroyer({collection: this}).destroy({workfileIds: ids});
    }
});
