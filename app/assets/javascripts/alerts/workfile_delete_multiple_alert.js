chorus.alerts.WorkfileDeleteMultiple = chorus.alerts.ModelDelete.extend({
    constructorName: "WorkfileDeleteMultiple",

    makeModel: function () {
        this.model = this.collection;
        this.count = this.collection.length;
        this._super("makeModel");
    },

    setup: function() {
        this._super("setup");

        this.text = t("workfile.delete.many.text", {count: this.count});
        this.title = t("workfile.delete.many.title");
        this.ok = t("workfile.delete.button");
        this.deleteMessage = "workfile.delete.many.toast";
        this.redirectUrl = this.collection.showUrl();
    },

    deleteMessageParams:function () {
        return {
            count: this.count
        };
    }
});

