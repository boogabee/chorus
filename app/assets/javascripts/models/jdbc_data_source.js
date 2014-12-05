chorus.models.JdbcDataSource = chorus.models.DataSource.extend({
    constructorName: "JdbcDataSource",
    urlTemplate: "data_sources/{{id}}",
    nameAttribute: 'name',
    entityType: "jdbc_data_source",

    showUrlTemplate: "data_sources/{{id}}/schemas",

    parameterWrapper: "data_source",

    defaults: {
        entityType: 'jdbc_data_source'
    },

    attrToLabel: {
        "dbUsername": "data_sources.dialog.database_account",
        "dbPassword": "data_sources.dialog.database_password",
        "name": "data_sources.dialog.data_source_name",
        "host": "data_sources.dialog.jdbc_url",
        "description": "data_sources.dialog.description"
    },

    schemas: function(){
        var collection = new chorus.collections.SchemaSet();
        collection.urlTemplate = "data_sources/"+this.get("id")+"/schemas";
        return collection;
    },

    isSingleLevelSource: function () {
        return true;
    },

    declareValidations: function(newAttrs) {
        this.require("name", newAttrs);
        this.requirePattern("name", chorus.ValidationRegexes.MaxLength64(), newAttrs);

        this.require("host", newAttrs);
        if (this.isNew()) {
            this.require("dbUsername", newAttrs);
            this.require("dbPassword", newAttrs);
        }
    }
});
