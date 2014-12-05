//= require ./data_source_set
chorus.collections.PgGpDataSourceSet = chorus.collections.DataSourceSet.extend({
    constructorName: "PgGpDataSourceSet",

    urlParams: function() {
        return _.extend(this._super('urlParams') || {}, {
            "entityType[]": ["gpdb_data_source", "pg_data_source"]
        });
    }
});
