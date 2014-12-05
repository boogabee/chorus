chorus.alerts.RemoveSharedAccount = chorus.alerts.Confirm.extend({
    constructorName: "RemoveSharedAccount",

    text:t("data_sources.remove_shared_account.text"),
    title:t("data_sources.remove_shared_account.title"),
    ok:t("data_sources.remove_shared_account.remove"),

    confirmAlert:function () {
        this.trigger("removeSharedAccount");
        this.closeModal();
    }
});

