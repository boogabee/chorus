chorus.pages.WorkspaceSearchIndexPage = chorus.pages.SearchIndexPage.extend({
    crumbs: [],

    parseSearchParams: function(searchParams) {
        var workspaceId = searchParams.shift();
        var result = this._super("parseSearchParams", [ searchParams ]);
        return _.extend(result, { workspaceId: workspaceId });
    },

    searchInMenuOptions: function() {
        return this._super("searchInMenuOptions", arguments).concat([
            { data: "this_workspace", text: t("search.in.this_workspace", {workspaceName: this.search.workspace().get("name")}) }
        ]);
    },

    typeOptions: function() {
        var options = this._super("typeOptions", arguments);
        if (this.search.isScoped()) {
            var toDisable = ["data_source", "user", "workspace", "hdfs_entry"];
            _.each(options, function(option) {
                if (_.include(toDisable, option.data)) {
                    option.disabled = true;
                }
            });
        }

        return options;
    },

    makeModel: function() {
        this._super("makeModel", arguments);
        this.workspaceId = this.search.get("workspaceId");
        this.workspace = this.search.workspace();
        this.requiredResources.add(this.workspace);
    },

    setup: function() {
        this._super("setup", arguments);
        this.listenTo(this.search.workspace(), "loaded", this.resourcesLoaded);
        this.workspace.fetch();
    },

    resourcesLoaded: function() {
        if(this.workspace.loaded && this.search.loaded) {
            this._super("resourcesLoaded", arguments);
        }
    }
});
