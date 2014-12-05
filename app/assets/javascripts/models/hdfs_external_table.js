chorus.models.HdfsExternalTable = chorus.models.Base.extend({
    constructorName: 'HdfsExternalTable',
    urlTemplate: function (options) {
        var defaultUrl = "hdfs_data_sources/{{hdfsDataSourceId}}/files/?id={{id}}";
        var postUrl = "workspaces/{{workspaceId}}/external_tables";

        var method = options && options.method;
        return (method === "create" ? postUrl : defaultUrl);
    },

    save: function(options) {
        return this._super("save", [options || {}, {method: "create"}]);
    },

    toJSON: function() {
        var hash = this._super('toJSON', arguments);
        hash.hdfs_external_table.pathname = hash.hdfs_external_table.path;
        delete hash.hdfs_external_table.path;
        return hash;
    }
});