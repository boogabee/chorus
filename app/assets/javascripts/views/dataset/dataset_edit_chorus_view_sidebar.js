chorus.views.DatasetEditChorusViewSidebar = chorus.views.Sidebar.extend({
    constructorName: "DatasetEditChorusViewSidebarView",
    templateName: "dataset_edit_chorus_view_sidebar",
    useLoadingSection: true,

    subviews: {
        '.tab_control': 'tabs'
    },

    setup: function(options) {
        this.collection = this.model.activities();
        this.collection.fetch();

        this.listenTo(this.collection, "changed", this.render);
        this.requiredResources.push(this.model);
    },

    resourcesLoaded: function() {
        this.tabs = new chorus.views.TabControl(["data", "database_function_list", "activity"]);
        this.schema = this.model.schema();

        this.tabs.database_function_list = new chorus.views.FunctionTab({ schema: this.schema });
        this.tabs.data = new chorus.views.DataTab({ schema: this.schema });
        this.tabs.activity = new chorus.views.ActivityList({
            collection: this.collection,
            additionalClass: "sidebar",
            displayStyle: ['without_object', 'without_workspace']
        });

        this.listenTo(this.tabs, 'selected', this.recalculateScrolling);
    }
});
