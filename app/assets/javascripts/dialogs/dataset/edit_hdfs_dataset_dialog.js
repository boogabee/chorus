//= require ./hdfs_dataset_attributes_dialog.js

chorus.dialogs.EditHdfsDataset = chorus.dialogs.HdfsDatasetAttributes.extend({
    constructorName: "EditHdfsDatasetDialog",
    title: t("edit_hdfs_dataset.title"),
    message: "edit_hdfs_dataset.toast",

    findModel: function () {
        return this.options.model;
    }
});