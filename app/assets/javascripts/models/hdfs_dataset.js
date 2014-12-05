chorus.models.HdfsDataset = chorus.models.WorkspaceDataset.extend({
    constructorName: "HdfsDataset",

    urlTemplate: function(options) {
        var method = options && options.method;
        if(method === "create" || method === "update" || method === "delete") {
            var base = "hdfs_datasets/";

            var completeUrl = this.id ? base + this.id : base;
            return completeUrl;
        } else {
            return "workspaces/{{workspace.id}}/datasets/{{id}}";
        }
    },

    iconUrl: function(options) {
        var size = (options && options.size) || "large";
        return "/images/hdfs_dataset_" + size + ".png";
    },

    showUrlTemplate: "workspaces/{{workspace.id}}/hadoop_datasets/{{id}}",

    initialize: function (options) {
        this._super('initialize');
        this.attributes.entitySubtype = "HDFS";
        this.attributes.objectType = "MASK";
        if (options && options.workspace) {
            this.attributes.workspaceId = options.workspace.id;
        }
    },

    dataSource: function() {
        return new chorus.models.HdfsDataSource(this.get("hdfsDataSource"));
    },

    content: function() {
        return (this.get("content") && this.get("content").join("\n")) || "";
    },

    asWorkspaceDataset: function() {
        return this;
    },

    canExport:function () {
        return false;
    },

    isDeleteable: function () {
        return true;
    }
});