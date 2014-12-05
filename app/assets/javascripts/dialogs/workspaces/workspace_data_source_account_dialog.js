chorus.dialogs.WorkspaceDataSourceAccount = chorus.dialogs.Account.extend({
    constructorName: "WorkspaceDataSourceAccount",

    translationKeys: {
        cancel: 'workspace.data_source.account.continue_without_credentials',
        body: 'workspace.data_source.account.body'
    },

    setup: function() {
        this.title = t('workspace.data_source.account.title');
    },

    additionalContext: function() {
        var results = this._super('additionalContext');
        results.translationValues.dataSourceName = this.pageModel.sandbox().database().dataSource().get("name");
        return results;
    }

});
