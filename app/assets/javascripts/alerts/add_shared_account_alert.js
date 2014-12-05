chorus.alerts.AddSharedAccount = chorus.alerts.Confirm.extend({
    constructorName: "AddSharedAccount",
    text: t("data_sources.add_shared_account.text"),
    title: t("data_sources.add_shared_account.title"),
    ok: t("data_sources.add_shared_account.enable"),

    confirmAlert: function() {
        this.trigger("addSharedAccount");
        this.closeModal();
    }
});