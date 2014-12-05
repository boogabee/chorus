chorus.models.Database = chorus.models.Base.include(
    chorus.Mixins.DataSourceCredentials.model
).extend({
    constructorName: "Database",
    showUrlTemplate: "databases/{{id}}",
    urlTemplate: "databases/{{id}}",

    dataSource: function() {
        var dataSource = this._dataSource || new chorus.models.DynamicDataSource(this.get("dataSource"));
        if(this.loaded) {
            this._dataSource = dataSource;
        }
        return dataSource;
    },

    schemas: function() {
        var schema = this._schemas || new chorus.collections.SchemaSet([], { databaseId: this.get('id') });
        if(this.loaded) {
            this._schemas = schema;
        }
        return schema;
    },

    parent: function() {
        return this.dataSource();
    }
});
