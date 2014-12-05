chorus.collections.DataSourceAccountSet = chorus.collections.Base.extend({
    constructorName: "DataSourceAccountSet",
    model: chorus.models.DataSourceAccount,
    urlTemplate: "data_sources/{{dataSourceId}}/members",

    users: function() {
        return this.map(function(model) {
            return model.user();
        });
    },

    urlParams: function() {
        return {
            dataSourceId: this.attributes.dataSourceId
        };
    },

    comparator: function(account) {
        var name = account.user() && (account.user().get("lastName") + account.user().get("firstName"));
        name = name ? name.toLowerCase() : '\uFFFF';  //'FFFF' should be the last possible unicode character
        return name;
    },

    persistedAccountCount: function() {
        return _.compact(this.pluck('id')).length;
    }
});