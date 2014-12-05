chorus.models.Schema = chorus.models.Base.include(
    chorus.Mixins.DataSourceCredentials.model
).extend({
    constructorName: "Schema",
    showUrlTemplate: "schemas/{{id}}",
    urlTemplate: "schemas/{{id}}",

    functions: function() {
        this._schemaFunctions = this._schemaFunctions || new chorus.collections.SchemaFunctionSet([], {
            id: this.get("id"),
            schemaName: this.get("name")
        });
        return this._schemaFunctions;
    },

    datasets: function() {
        if(!this._datasets) {
            this._datasets = new chorus.collections.SchemaDatasetSet([], { schemaId: this.id });
        }
        return this._datasets;
    },

    tables: function() {
        if(!this._tables) {
            this._tables = new chorus.collections.SchemaDatasetSet([], {schemaId: this.id, tablesOnly: "true"});
        }
        return this._tables;
    },

    parent: function() {
        return this.database() || this.dataSource();
    },

    database: function() {
        var database = this._database || (this.get("database") && new chorus.models.Database(this.get("database")));
        if(this.loaded) {
            this._database = database;
        }
        return database;
    },

    dataSource: function() {
        var dataSource = this._dataSource;
        if(!this._dataSource) {
            if(this.has('dataSource')) {
                dataSource = new chorus.models.DynamicDataSource(this.get('dataSource'));
            } else {
                dataSource = this.database().dataSource();
            }
        }
        if(this.loaded) {
            this._dataSource = dataSource;
        }
        return dataSource;
    },

    canonicalName: function() {
        return _.compact([this.dataSource().name(), this.database() && this.database().name(), this.name()]).join(".");
    },

    isEqualToSchema: function(other) {
        return this.get("id") === other.get("id");
    }
}, {
    DEFAULT_NAME: "public"
});
