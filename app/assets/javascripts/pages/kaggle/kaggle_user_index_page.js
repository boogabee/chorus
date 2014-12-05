chorus.pages.KaggleUserIndexPage = chorus.pages.Base.extend({
    constructorName: "KaggleUserIndexPage",
    additionalClass: 'kaggle_user_list',

    setup: function() {
        this.collection = new chorus.collections.KaggleUserSet([]);
        this.handleFetchErrorsFor(this.collection);
        this.collection.fetch();

        this.mainContent = new chorus.views.MainContentList({
            modelClass: "KaggleUser",
            collection: this.collection,
            contentHeader: new chorus.views.KaggleHeader(),
            contentDetails: new chorus.views.KaggleUserListContentDetails({collection: this.collection})
        });

        this.multiSelectSidebarMenu = new chorus.views.MultipleSelectionSidebarMenu({
            selectEvent: "kaggle_user:checked",
            actionProvider: [
                { name: "send_message", target: chorus.dialogs.ComposeKaggleMessage }
            ]
        });

        this.sidebar = new chorus.views.KaggleUserSidebar({workspace: this.workspace});

        this.subscribePageEvent("filterKaggleUsers", this.filterKaggleUsers);

        this.requiredResources.add(this.workspace);
    },

    makeModel: function(workspaceId) {
        this.loadWorkspace(workspaceId);
    },

    filterKaggleUsers: function(filterCollection) {
        var paramArray = _.compact(filterCollection.map(function(model) {
            return model.filterParams();
        }));
        this.collection.urlParams = {'filters[]': paramArray};
        this.collection.fetch();
    }
});