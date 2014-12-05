chorus.collections.HdfsDataSourceSet = chorus.collections.Base.extend({
    constructorName: "HdfsDataSourceSet",
    model: chorus.models.HdfsDataSource,
    urlTemplate: "hdfs_data_sources",

    comparator: function(data_source) {
        return data_source.get("name").toLowerCase();
    },

    urlParams: function () {
        var params = {};

        if (this.attributes.succinct) {
            params.succinct = true;
        }

        if (this.attributes.jobTracker) {
            params.jobTracker = true;
        }

        return params;
    }
});
