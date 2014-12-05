chorus.alerts.MultipleJobDelete = chorus.alerts.CollectionDelete.extend({
    constructorName: "MultipleJobDelete",

    setup: function () {
        this.text = t("job_delete.multiple.text", {count: this.count});
        this.title = t("job_delete.multiple.title");
        this.ok = t("job_delete.multiple.ok");
        this.deleteMessage = "job_delete.multiple.toast";
    },

    deleteMessageParams:function () {
        return { count: this.count, plurality: this.count > 1 ? 's' : '' };
    },

    makeModel:function () {
        this.collection = this.options.collection;
        this.count = this.collection.length;
        this.redirectUrl = this.collection.at(0).workspace().jobsUrl();
    }
});