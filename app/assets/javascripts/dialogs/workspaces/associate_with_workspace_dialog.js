chorus.dialogs.AssociateWithWorkspace = chorus.dialogs.PickWorkspace.extend({
    constructorName: "AssociateWithWorkspace",

    title: t("dataset.associate.title.one"),
    submitButtonTranslationKey: "dataset.associate.button.one",

    setup: function() {
        this.requiredResources.add(this.collection);
        this._super('setup', arguments);
    },

    resourcesLoaded: function() {
        this.collection.reset(this.collection.reject(function (workspace) {
            return ( ( (workspace.get('showSandboxDatasets') && workspace.sandbox() && this.model.schema().get('id') === workspace.sandbox().get('id'))));
        }, this));

        if (this.model.has("workspace")) {
            this.collection.remove(this.collection.get(this.model.workspace().id));
        }

        this.model.workspacesAssociated().each(function(workspace) {
            this.collection.remove(this.collection.get(workspace.id));
        }, this);

        this.render();
    },

    submit: function() {
        var datasetSet = this.selectedItem().datasets();
        datasetSet.reset([this.model]);
        this.listenTo(datasetSet, "saved", this.saved);
        this.listenTo(datasetSet, "saveFailed", this.saveFailed);

        datasetSet.save();
        this.$("button.submit").startLoading("actions.associating");
    },

    saved: function() {
        this.model.activities().fetch();
        this.model.fetch();
        this.closeModal();
        chorus.toast("dataset.associate.toast.one", {datasetTitle: this.model.get("objectName"), workspaceNameTarget: this.selectedItem().get("name")});
    }
});
