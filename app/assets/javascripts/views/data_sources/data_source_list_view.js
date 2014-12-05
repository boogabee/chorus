chorus.views.DataSourceList = chorus.views.Base.extend({
    constructorName: "DataSourceListView",
    templateName: "data_source_list",

    subviews: {
        ".list": "list"
    },

    setup: function() {
        this.entityType = this.options.entityType;
        this.selectedModels = this.options.selectedModels;
        this.list = this.buildList();
        this.resource = this.collection = this.options.collection;
    },

    buildList: function() {
        return new chorus.views.PageItemList({
            eventName: "data_source",
            collection: this.collection,
            entityViewType: chorus.views.DataSourceItem,
            selectedModels: this.selectedModels,
            multiListMode: true
        });
    },

    additionalContext: function() {
        return {
            entityType: this.entityType,
            empty: this.collection.length === 0,
            title: this.title()
        };
    },

    title: function() {
        return t("data_sources.list.type." + this.entityType);
    }
});