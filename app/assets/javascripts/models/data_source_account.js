chorus.models.DataSourceAccount = chorus.models.Base.extend({
    constructorName: "DataSourceAccount",
    parameterWrapper: "account",
    paramsToIgnore: ['owner'],

    urlTemplate: function(options) {
        var method = options && options.method;
        var isEditingOwnAccount = this.get("userId") === chorus.session.user().id;

        if (isEditingOwnAccount) {
            return "data_sources/{{dataSourceId}}/account";
        }

        if (method === "update" || method === "delete") {
            return "data_sources/{{dataSourceId}}/members/{{id}}";
        }

        return "data_sources/{{dataSourceId}}/members";
    },

    user: function() {
        return this.get("owner") && new chorus.models.User(this.get('owner'));
    },

    declareValidations: function(newAttrs) {
        this.require('dbUsername', newAttrs);

        if (this.isNew() || (newAttrs && newAttrs.hasOwnProperty('dbPassword'))) {
            this.require('dbPassword', newAttrs);
        }
    },

    attrToLabel: {
        "dbUsername": "data_sources.permissions.username",
        "dbPassword": "data_sources.permissions.password"
    }
}, {
    findBydataSourceId: function(dataSourceId) {
        var account = new chorus.models.DataSourceAccount({ dataSourceId: dataSourceId });
        account.fetch();
        return account;
    },

    currentUserCanUpdateCredentialsFor: function(dataSource) {
        var user = chorus.session.user();

        var userIsAdmin         = user.isAdmin();
        var dataSourceIsShared  = dataSource.get('shared');
        var userIsOwner         = dataSource.get('ownerId') === user.get('id');

        return (userIsAdmin || userIsOwner || !dataSourceIsShared);
    }
});
