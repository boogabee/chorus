chorus.alerts.DatasetDelete = chorus.alerts.ModelDelete.extend({
    constructorName: "DatasetDelete",

    setup: function() {
        this._super("setup");

        var keyPrefix = this.options.keyPrefix;
        this.text = t("dataset_delete." + keyPrefix + ".text");
        this.title = t("dataset_delete." + keyPrefix + ".title");
        this.ok = t("dataset_delete." + keyPrefix + ".button");
        this.deleteMessage = "dataset_delete." + keyPrefix + ".toast";
    },

    deleteMessageParams:function () {
        return {
            datasetName:this.datasetName
        };
    },

    makeModel:function () {
        this._super("makeModel", arguments);
        this.model = this.model || this.pageModel;
        this.datasetName = this.model.name();
        this.redirectUrl = this.model.workspace().datasets().showUrl();
    }
});