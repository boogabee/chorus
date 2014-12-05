chorus.models.GpdbDataSource = chorus.models.DataSource.extend({
    constructorName: "GpdbDataSource",
    urlTemplate: "data_sources/{{id}}",
    nameAttribute: 'name',
    entityType: "gpdb_data_source",

    showUrlTemplate: "data_sources/{{id}}/databases",

    parameterWrapper: "data_source",

    defaults: {
        entityType: 'gpdb_data_source'
    },

    databases: function() {
        this._databases || (this._databases = new chorus.collections.DatabaseSet([], {dataSourceId: this.get("id")}));
        return this._databases;
    },

    attrToLabel: {
        "dbUsername": "data_sources.dialog.database_account",
        "dbPassword": "data_sources.dialog.database_password",
        "name": "data_sources.dialog.data_source_name",
        "host": "data_sources.dialog.host",
        "port": "data_sources.dialog.port",
        "databaseName": "data_sources.dialog.database_name",
        "dbName": "data_sources.dialog.db_name",
        "description": "data_sources.dialog.description"
    }
});
