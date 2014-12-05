chorus.models.DataSourceUsage = chorus.models.Base.extend({
    constructorName: "DataSourceUsage",
    urlTemplate:"data_sources/{{dataSourceId}}/workspace_detail",

    workspaceCount: function() {
        return this.get("workspaces") && this.get("workspaces").length;
    }
});
