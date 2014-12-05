chorus.views.SearchResultList = chorus.views.Base.extend({
    constructorName: "SearchResultList",
    templateName: "search_result_list",

    events: {
        "click a.show_all": "showAll"
    },

    subviews: {
        ".list": "list"
    },

    setup: function() {
        this.search = this.options.search;
        this.entityType = this.options.entityType;
        this.selectedModels = this.options.selectedModels;
        this.list = this.buildList();
        this.subscribePageEvent("selected", this.saveSearchSelection);
    },

    saveSearchSelection: function(model) {
        this.search.selectedItem = model;
    },

    buildList: function() {
        return new chorus.views.PageItemList({
            collection: this.collection,
            entityViewType: chorus.views["Search" + _.classify(this.options.entityType)],
            listItemOptions: {
                workspaceIdForTagLink: this.options.search.get('workspaceId')
            },
            selectedModels: this.selectedModels,
            multiListMode: true,
            eventName: this.options.entityType
        });
    },

    additionalContext: function() {
        return {
            entityType: this.entityType,
            shown: this.collection.models.length,
            total: this.collection.pagination.records,
            hideHeaders: this.search && this.search.isPaginated() && !this.search.workspace(),
            moreResults: this.moreRecordsThanShown(),
            title: this.title()
        };
    },

    title: function() {
            return t("search.type." + this.entityType);
        },

    moreRecordsThanShown: function () {
        var localModels = this.collection.models;
        var remoteModelCount = this.collection.pagination.records;
        return (localModels.length < remoteModelCount);
    },

    showAll: function(e) {
        e.preventDefault();
        this.search.set({entityType: $(e.currentTarget).data("type")});
        delete this.search.attributes.workspaceId;
        chorus.router.navigate(this.search.showUrl());
    }
});
