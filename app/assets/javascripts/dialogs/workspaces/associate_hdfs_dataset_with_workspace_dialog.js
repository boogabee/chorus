chorus.dialogs.HdfsDatasetWorkspacePicker = chorus.dialogs.PickWorkspace.extend({
    constructorName: "HdfsDatasetWorkspacePicker",
    title: t("hdfs_dataset.workspace_picker.title"),
    selectedEvent: "workspace:selected",
    submitButtonTranslationKey: "hdfs_dataset.workspace_picker.submit",

    preInitialize: function() {
        this.options.activeOnly = true;
        this._super("preInitialize", arguments);
    }
});
