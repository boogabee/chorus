chorus.alerts.RemoveIndividualAccount = chorus.alerts.Confirm.extend({
    constructorName: "RemoveIndividualAccount",

    ok:t("data_sources.remove_individual_account.remove"),

    setup: function() {
        this.title = t("data_sources.remove_individual_account.title", {dataSourceName: this.options.dataSourceName, userName: this.options.name});
    },

    confirmAlert:function () {
        this.trigger("removeIndividualAccount");
        this.closeModal();
    }
});

