//= require ./hdfs_dataset_attributes_dialog.js

chorus.dialogs.CreateHdfsDataset = chorus.dialogs.HdfsDatasetAttributes.extend({
    title: t("create_hdfs_dataset_dialog.title"),
    message: "create_hdfs_dataset_dialog.toast",

    findModel: function () {
        this.workspace = this.options.pageModel;
        return new chorus.models.HdfsDataset({ workspace: {id: this.workspace.id} });
    },

    loadDataSources: function() {
        this.dataSources = new chorus.collections.HdfsDataSourceSet();
        this.dataSources.fetchAll();
        this.onceLoaded(this.dataSources, this.dataSourcesLoaded);
    },

    checkDataSource: function () {
        return this.$("select").val().trim();
    },

    modelSaved: function () {
        this._super("modelSaved");
        chorus.router.navigate(this.model.showUrl());
    },

    additionalContext: function() {
        return {
            loaded: this.dataSources.loaded,
            dataSources: this.dataSources.models,
            dataSourcesLoaded: this.dataSources.length > 0,
            needsDataSource: true
        };
    },

    postRender: function() {
        this.$(".loading_spinner").startLoading();
        chorus.styleSelect(this.$(".data_source select"));
    },

    dataSourcesLoaded: function() {
        this.render();
    }
});