chorus.dialogs.RunAndDownload = chorus.dialogs.DatasetDownload.extend({
    constructorName: "RunAndDownload",
    submitKey: "workfile.run_and_download_dialog.run",

    persistent:true,

    setTitle: function() {
        this.title = t("workfile.run_and_download_dialog.title");
    },

    downloadAll: function() {
        chorus.PageEvents.trigger("file:runAndDownload", this.options);
        this.closeModal();
    },

    downloadSome: function() {
        chorus.PageEvents.trigger("file:runAndDownload", _.extend({numOfRows: this.rowLimit()}, this.options));
        this.closeModal();
    }
});