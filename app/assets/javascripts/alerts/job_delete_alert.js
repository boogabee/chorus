chorus.alerts.JobDelete = chorus.alerts.ModelDelete.extend({
    constructorName: "JobDelete",

    text: t("job_delete.text"),
    title: t("job_delete.title"),
    ok: t("job_delete.ok"),
    deleteMessage: "job_delete.toast",

    deleteMessageParams:function () {
        return { jobName: this.modelName };
    },

    makeModel:function () {
        this._super("makeModel", arguments);
        this.model = this.model || this.pageModel;
        this.modelName = this.model.name();
        this.redirectUrl = this.model.workspace().jobsUrl();
    }
});

