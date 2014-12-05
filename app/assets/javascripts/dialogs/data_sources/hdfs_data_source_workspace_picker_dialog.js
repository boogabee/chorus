chorus.dialogs.HdfsDataSourceWorkspacePicker = chorus.dialogs.PickWorkspace.extend({
    constructorName: "HdfsDataSourceWorkspacePicker",

    title: t("hdfs_data_source.workspace_picker.title"),
    submitButtonTranslationKey: "hdfs_data_source.workspace_picker.button",

    setup: function() {
        this.requiredResources.add(this.collection);
        this._super("setup", arguments);
        this.subscribePageEvent("csv_import:started", this.closeDialog);
    },

    resourcesLoaded: function() {
        var noSandboxes = this.collection.select(function(ws) {
            return !ws.sandbox();
        });
        this.collection.remove(noSandboxes, {silent: true});
        this.render();
    },

    closeDialog: function() {
        this.closeModal();
    },

    submit : function() {
        if(this.selectedItem().sandbox().dataSource().version() < "4.2") {
            this.showDialogError(t("hdfs_data_source.gpdb_version.too_old_42"));
            return;
        }

        this.hdfsFiles = new chorus.collections.CsvHdfsFileSet([], {
            hdfsDataSource : this.model.get("hdfsDataSource"),
            id: this.model.get("id")
        });
        this.hdfsFiles.bindOnce("loaded", this.launchCreateHdfsDialog, this);
        this.hdfsFiles.fetchAll();
        this.trigger("workspace:selected", this.selectedItem());
    },

    launchCreateHdfsDialog: function() {
        var hdfsTextFiles = this.hdfsFiles.removeDirectories();

        if (hdfsTextFiles.length === 0) {
            this.showDialogError(t("hdfs_data_source.no_text_files"));
        } else {
            this.externalTableDialog = new chorus.dialogs.CreateDirectoryExternalTableFromHdfs({
                collection: hdfsTextFiles || [],
                directoryName: this.model.get("name"),
                workspaceId: this.selectedItem().id,
                workspaceName: this.selectedItem().get("name"),
                csvOptions: {
                    contents: hdfsTextFiles.models[0].get('contents')
                },
                hdfs_entry_id: this.model.get('id')
            });
            this.launchSubModal(this.externalTableDialog);
        }
    }
});
