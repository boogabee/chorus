chorus.alerts.DataSourceChangedOwner = chorus.alerts.Confirm.extend({
    constructorName: "DataSourceChangedOwner",

    text:t("data_sources.confirm_change_owner.text"),
    ok:t("data_sources.confirm_change_owner.change_owner"),

    setup:function () {
        this.title = t("data_sources.confirm_change_owner.title", { displayName:this.model.displayName() });
    },

    confirmAlert:function () {
        this.trigger("confirmChangeOwner", this.model);
        this.closeModal();
    }
});

