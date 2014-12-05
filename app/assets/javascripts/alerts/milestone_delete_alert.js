chorus.alerts.MilestoneDelete = chorus.alerts.ModelDelete.extend({
    constructorName: "MilestoneDelete",

    text: t("milestone_delete.text"),
    title: t("milestone_delete.title"),
    ok: t("milestone_delete.ok"),
    deleteMessage: "milestone_delete.toast",

    deleteMessageParams:function () {
        return { milestoneName: this.modelName };
    },

    makeModel:function () {
        this._super("makeModel", arguments);
        this.model = this.model || this.pageModel;
        this.modelName = this.model.name();
        this.redirectUrl = this.model.workspace().milestonesUrl();
    }
});