chorus.collections.SchemaDatasetSet = chorus.collections.LastFetchWins.include(
    chorus.Mixins.DataSourceCredentials.model,
    chorus.Mixins.CollectionFetchingSearch
).extend({
    constructorName: 'SchemaDatasetSet',
    model: chorus.models.DynamicDataset,
    urlTemplate: "schemas/{{schemaId}}/datasets",
    searchAttr: "filter",

    urlParams: function() {
        if (this.attributes) {
            var paramsList = {};
            if(this.attributes.filter){
                paramsList['filter'] = this.attributes.filter;
            }
            if(this.attributes.tablesOnly) {
                paramsList['tablesOnly'] = this.attributes.tablesOnly;
            }
            return paramsList;
        }
    }
});
