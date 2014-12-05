chorus.dialogs.DataSourceAccount = chorus.dialogs.Account.extend({
    constructorName: "DataSourceAccount",

    translationKeys: {
        cancel: 'actions.cancel',
        body: 'data_sources.account.enter_credentials'
    },

    setup: function() {
        this.title = this.options.title;
    },

    makeModel: function(options) {
        var dataSource = this.options.dataSource;
        this.model = dataSource.accountForCurrentUser();
        this._super("makeModel", arguments);
    },

    modalClosed: function() {
        this._super("modalClosed", arguments);
        if(this.options.reload && this.savedSuccessfully) {
            chorus.router.reload();
        }
        if(this.options.goBack && !this.savedSuccessfully) {
            window.history.back();
        }
    },

    saved: function() {
        this.savedSuccessfully = true;
        this._super('saved');
    }
});
