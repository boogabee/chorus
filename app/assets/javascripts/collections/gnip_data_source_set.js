chorus.collections.GnipDataSourceSet = chorus.collections.Base.extend({
    constructorName: "GnipDataSourceSet",
    model: chorus.models.GnipDataSource,
    urlTemplate: "gnip_data_sources",

    comparator: function(dataSource) {
        return dataSource.get("name").toLowerCase();
    },

    urlParams: function () {
        var params = {};

        if (this.attributes.succinct) {
            params.succinct = true;
        }

        return params;
    }
});
