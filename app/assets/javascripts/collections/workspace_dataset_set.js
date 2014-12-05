chorus.collections.WorkspaceDatasetSet = chorus.collections.LastFetchWins.include(
    chorus.Mixins.CollectionFetchingSearch
).extend({
    constructorName: "WorkspaceDatasetSet",
    showUrlTemplate: "workspaces/{{workspaceId}}/datasets",
    urlTemplate: "workspaces/{{workspaceId}}/datasets",
    model: chorus.models.DynamicDataset,
    searchAttr: "namePattern",

    setup: function() {
        if(this.attributes.unsorted) {
            this.comparator = undefined;
        }
    },

    save: function() {
        var ids = _.pluck(this.models, 'id');
        new chorus.models.BulkSaver({collection: this}).save({datasetIds: ids});
    },

    destroy: function() {
        var ids = _.pluck(this.models, 'id');
        new chorus.models.BulkDestroyer({collection: this}).destroy({datasetIds: ids});
    },

    urlParams: function(options) {
        var params = {
            namePattern: this.attributes.namePattern,
            databaseId: this.attributes.database && this.attributes.database.id,
            entitySubtype: this.attributes.type
        };

        if (this.attributes.allImportDestinations) {
            params.allImportDestinations = true;
        }
        if (this.attributes.allImportSources) {
            params.allImportSources = true;
        }
        return params;
    },

    comparator: function(dataset) {
        return dataset.get("objectName").replace('_', '').toLowerCase();
    },

    hasFilter: function() {
        return !_.isEmpty(this.attributes.namePattern) || !_.isEmpty(this.attributes.type);
    }
});
