chorus.views.SearchResults = chorus.views.Base.extend({
    constructorName: "SearchResults",
    templateName: "search_results",

    subviews: {
        ".this_workspace":       "thisWorkspaceList",
        ".hdfs_list":            "hdfsList",
        ".user_list":            "userList",
        ".workfile_list":        "workfileList",
        ".workspace_list":       "workspaceList",
        ".dataset_list":         "datasetList",
        ".data_source_list":        "dataSourceList",
        ".hdfs_data_source_list": "hdfsDataSourceList",
        ".gnip_data_source_list":   "gnipDataSourceList",
        ".attachment_list":      "attachmentList"
    },

    setup: function() {
        this.selectedModels = new chorus.collections.Base();

        if (this.model.hdfs_entries().length) {
            this.hdfsList = this.buildListView('hdfs_entry', this.model.hdfs_entries());
        }
        if (this.model.users().length) {
            this.userList = this.buildListView('user', this.model.users());
        }
        if (this.model.workfiles().length) {
            this.workfileList = this.buildListView('workfile', this.model.workfiles());
        }
        if (this.model.workspaces().length) {
            this.workspaceList = this.buildListView('workspace', this.model.workspaces());
        }
        if (this.model.datasets().length) {
            this.datasetList = this.buildListView('dataset', this.model.datasets());
        }
        if (this.model.dataSources().length) {
            this.dataSourceList = this.buildListView('data_source', this.model.dataSources());
        }
        if (this.model.attachments().length) {
            this.attachmentList = this.buildListView('attachment', this.model.attachments());
        }
        if (this.model.workspaceItems().length) {
            this.thisWorkspaceList = new chorus.views.WorkspaceSearchResultList({
                collection: this.model.workspaceItems(),
                search: this.model,
                selectedModels: this.selectedModels
            });
        }
    },

    additionalContext: function() {
        return {
            hasResults: this.model.total() > 0,
            isConstrained: this.model.isConstrained(),
            expandHref: new chorus.models.SearchResult({ query: this.model.get("query") }).showUrl()
        };
    },

    buildListView: function(entityType, collection) {
        return new chorus.views.SearchResultList({
            entityType: entityType,
            collection: collection,
            search: this.model,
            selectedModels: this.selectedModels
        });
    },

    selectItem:function selectItem(e) {
        var $target = $(e.currentTarget);
        if ($target.hasClass("selected")) return;

        this.$(".item_wrapper").removeClass("selected");
        $target.addClass("selected");
    }
});
