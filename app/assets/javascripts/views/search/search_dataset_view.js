chorus.views.SearchDataset = chorus.views.SearchItemBase.extend({
    constructorName: "SearchDatasetView",
    templateName: "search_dataset",

    additionalContext: function() {
        var context = _.extend(this._super("additionalContext"), {
            dataset: this.model.asWorkspaceDataset(),
            showUrl: this.model.showUrl(),
            iconUrl: this.model.iconUrl()
        });

        if (this.model.get("workspaces")) {
            context.workspaces = this.model.get("workspaces");
        } else if (this.model.get("workspace")) {
            context.workspaces = [this.model.get("workspace")];
        }

        return context;
    },

    postRender: function() {
        this._super("postRender");

        this.$("a.data_source, a.database").data("data_source", this.model.get("data_source"));
        this.menu(this.$(".location .found_in a.open_other_menu"), {
            content: this.$(".other_menu"),
            classes: "found_in_other_workspaces_menu"
        });
    }
});
