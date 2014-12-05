chorus.models.OracleDataSource = chorus.models.DataSource.extend({
    constructorName: "OracleDataSource",
    urlTemplate: "data_sources/{{id}}",
    nameAttribute: 'name',
    entityType: "oracle_data_source",

    showUrlTemplate: "data_sources/{{id}}/schemas",

    parameterWrapper: "data_source",

    defaults: {
        entityType: 'oracle_data_source'
    },

    attrToLabel: {
        "dbUsername": "data_sources.dialog.database_account",
        "dbPassword": "data_sources.dialog.database_password",
        "name": "data_sources.dialog.data_source_name",
        "host": "data_sources.dialog.host",
        "port": "data_sources.dialog.port",
        "dbName": "data_sources.dialog.database_name",
        "description": "data_sources.dialog.description"
    },

    schemas: function(){
        var collection = new chorus.collections.SchemaSet();
        collection.urlTemplate = "data_sources/"+this.get("id")+"/schemas";
        return collection;
    },

    isSingleLevelSource: function () {
        return true;
    }
});
