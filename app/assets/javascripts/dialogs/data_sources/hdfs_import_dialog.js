chorus.dialogs.HdfsImportDialog = chorus.dialogs.Upload.extend({
    constructorName: "HdfsImportDialog",
    title: t("hdfs.import.dialog.title"),
    submitKey: "hdfs.import.create",

    makeModel: function() {
        this._super("makeModel", arguments);
        this.hdfsEntry = this.options.pageModel;
    },

    maxFileSize: function() {
        return this.config.get("fileSizesMbHdUpload");
    },

    uploadSuccess: function(e, data) {
        this.upload.set(this.upload.parse(data.result));
        this.hdfsImport = new chorus.models.HdfsImport({
            uploadId: this.upload.id,
            hdfsEntryId: this.hdfsEntry.id,
            hdfsDataSourceId: this.hdfsEntry.getHdfsDataSource().id
        });

        this.listenTo(this.hdfsImport, "saved", this.saved);
        this.listenTo(this.hdfsImport, "saveFailed", this.saveFailed);
        this.hdfsImport.save();
    },

    saved: function() {
        chorus.toast("hdfs.import.started");
        this.closeModal();
    },

    saveFailed: function() {
        this.closeModal();
        this.hdfsImport.set({fileName: this.upload.get("fileName")});
        new chorus.dialogs.HdfsImportConflict({model: this.hdfsImport}).launchModal();
    }
});
