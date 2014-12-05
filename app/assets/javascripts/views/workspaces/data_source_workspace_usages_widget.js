chorus.views.DataSourceWorkspaceUsagesWidget = chorus.views.Base.extend({
    templateName: "data_source_workspace_usages",
    tagName: "li",

    events: {
        "click a.workspace_usage": "launchUsageDialog"
    },

    setup: function() {
        this.setDataSource(this.model);
    },

    setDataSource: function(dataSource) {
        this.dataSource = dataSource;
        this.dataSourceUsage && this.stopListening(this.dataSourceUsage);
        this.dataSourceUsage = this.dataSource && this.dataSource.usage();
        if(this.dataSourceUsage) {
            this.listenTo(this.dataSourceUsage, "loaded", this.render);
            this.listenTo(this.dataSourceUsage, "fetchFailed", this.render);
            this.dataSourceUsage.fetchIfNotLoaded();
        }
    },

    postRender: function() {
        if(this.dataSource.usage().loaded) {
            this.$el.empty();
            if(this.dataSource.hasWorkspaceUsageInfo()) {
                var el;
                var count = this.dataSource.usage().workspaceCount();
                if(count > 0) {
                    el = $("<a class='dialog workspace_usage' href='#'></a>");
                } else {
                    el = $("<span class='disabled workspace_usage'></span>");
                }
                el.text(t("data_sources.sidebar.usage", {count: count}));
                this.$el.append(el);
            }
        }
        else {
            this.$el.html('<span class="disabled workspace_usage">' + t("data_sources.sidebar.usage_loading") + '</span>');
        }
    },

    launchUsageDialog: function(e) {
        e && e.preventDefault();
        new chorus.dialogs.DataSourceUsage({dataSource: this.dataSource}).launchModal();
    }
});