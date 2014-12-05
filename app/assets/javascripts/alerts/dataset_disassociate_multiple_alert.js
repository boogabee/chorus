chorus.alerts.DatasetDisassociateMultiple = chorus.alerts.ModelDelete.extend({
    constructorName: "DatasetDisassociateMultiple",

    makeModel: function () {
    // Yes, this is silly.  If you want it to make more sense, try extending CollectionDelete.
      this.model = this.collection;
      this._super("makeModel");
    },

    setup: function() {
        this._super("setup");

        this.text = t("dataset_delete.many.text");
        this.title = t("dataset_delete.many.title");
        this.ok = t("dataset_delete.many.button");
        this.deleteMessage = "dataset_delete.many.toast";
        this.redirectUrl = this.collection.showUrl();
    },

    deleteMessageParams:function () {
        return {
            count: this.collection.length
        };
    }
});

