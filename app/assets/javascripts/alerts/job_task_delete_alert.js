chorus.alerts.JobTaskDelete = chorus.alerts.ModelDelete.extend({
    constructorName: "JobTaskDelete",

    text: t("job_task_delete.text"),
    title: t("job_task_delete.title"),
    ok: t("job_task_delete.ok"),
    deleteMessage: "job_task_delete.toast",

    makeModel:function () {
        this._super("makeModel", arguments);
        this.model = this.model || this.pageModel;
        this.modelName = this.model.name();
        this.redirectUrl = this.model.job().url();
    }
});