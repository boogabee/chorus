chorus.alerts.DataSourceAccountDelete = chorus.alerts.ModelDelete.extend({
    constructorName: "DataSourceAccountDelete",

    text:t("data_sources.account.delete.text"),
    title:t("data_sources.account.delete.title"),
    ok:t("data_sources.account.delete.button"),
    deleteMessage: "data_sources.account.delete.toast",

    makeModel:function () {
        this._super("makeModel", arguments);
        this.model = this.options.dataSource.accountForCurrentUser();
    }
});
