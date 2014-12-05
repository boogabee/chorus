chorus.dialogs.WorkFlowNewForDatasetList = chorus.dialogs.WorkFlowNewBase.extend({
    userWillPickSchema: false,

    checkInput: function() {
        return this.getFileName().trim().length > 0;
    },

    resourceAttributes: function () {
        return {
            fileName: this.getFileName(),
            datasetIds: this.collection.pluck('id')
        };
    }
});
