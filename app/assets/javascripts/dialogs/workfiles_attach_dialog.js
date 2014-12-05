chorus.dialogs.WorkfilesAttach = chorus.dialogs.PickItems.extend({
    constructorName: "WorkfilesAttachDialog",

    title: t("workfiles.attach"),
    submitButtonTranslationKey: "workfiles.button.attach_file",
    emptyListTranslationKey: "workfiles.none",
    searchPlaceholderKey: "workfiles.dialog.search",
    selectedEvent: 'files:selected',
    modelClass: "Workfile",
    multiSelection: true,

    makeModel:function () {
        this.collection = new chorus.collections.WorkfileSet([], {workspaceId:this.options.workspaceId || this.options.workspaceId });
        this.collection = new chorus.collections.FilteringCollection(null, {collection: this.collection});
        this.collection.fetchAll();
    },

    collectionModelContext: function (model) {
        return {
            name: model.get("fileName"),
            imageUrl: model.iconUrl({size:"icon"})
        };
    },

    collectionComparator: function(model) {
        return -(chorus.parseDateFromApi(model.get("versionInfo").updatedAt).getTime());
    }
});
