chorus.pages.JobsIndexPage = chorus.pages.Base.include(
        chorus.Mixins.FetchingListSearch
    ).extend({
    constructorName: 'JobsIndexPage',

    setup: function (workspaceId) {
        this.subNav = new chorus.views.SubNav({workspace: this.workspace, tab: "jobs"});

        this.collection = new chorus.collections.JobSet([], {workspaceId: workspaceId});
        this.collection.sortAsc("name");
        this.handleFetchErrorsFor(this.collection);
        this.collection.fetch();
        this.setupOnSearched();
        this.onceLoaded(this.collection, this.pollForJobs);

        this.mainContent = new chorus.views.MainContentList(this.listConfig());

        this.multiSelectSidebarMenu = new chorus.views.MultipleSelectionSidebarMenu(this.multiSelectSidebarConfig());

        this.mainContent.contentHeader.bind("choice:sort", function(choice) {
            var field = choice === "alpha" ? "name" : "nextRun";
            this.collection.sortAsc(field);
            this.collection.fetch();
        }, this);

        this.subscribePageEvent("job:search", function() {
            chorus.PageEvents.trigger('selectNone');
        });

        this.subscribePageEvent("job:selected", this.jobSelected);

        this.requiredResources.add(this.workspace);
    },

    preRender: function () {
        this.buildPrimaryActionPanel();
    },

    makeModel: function(workspaceId) {
        this.loadWorkspace(workspaceId);
    },

    jobSelected: function (job) {
        if(this.sidebar) this.sidebar.teardown(true);

        this.sidebar = new chorus.views.JobSidebar({model: job});
        this.renderSubview('sidebar');
    },

    listConfig: function () {
        return {
            modelClass: "Job",
            collection: this.collection,
            model: this.workspace,
            contentDetailsOptions: { multiSelect: true },
            linkMenus: {
                sort: {
                    title: t("job.header.menu.sort.title"),
                    options: [
                        {data: "alpha", text: t("job.header.menu.sort.alphabetically")},
                        {data: "date", text: t("job.header.menu.sort.by_date")}
                    ],
                    event: "sort"
                }
            },
            search: {
                placeholder: t("job.search_placeholder"),
                eventName: "job:search",
                onTextChange: this.debouncedCollectionSearch()
            }
        };
    },

    multiSelectSidebarConfig: function () {
        return {
            selectEvent: "job:checked",
            actionProvider: [
                {name: 'disable', target: 'disable'},
                {name: 'enable', target: 'enable'},
                {name: 'delete', target: chorus.alerts.MultipleJobDelete}
            ]
        };
    },

    pollForJobs: function () {
        this.collectionFetchPollerID && clearInterval(this.collectionFetchPollerID);

        var fetchCollection = _.bind(function () {
            this.lastSearchValue = $('.chorus_search').val();
            this.collection.fetch({
                success: _.bind(function() {
                    $('.chorus_search').val(this.lastSearchValue);
                    $('.chorus_search').trigger('onTextChange');
                }, this)
            });
        }, this);
        this.collectionFetchPollerID = setInterval(fetchCollection, 15000);
    },

    teardown: function () {
        clearInterval(this.collectionFetchPollerID);
        return this._super('teardown');
    },

    buildPrimaryActionPanel: function () {
        var canUpdate = this.workspace.isActive() && this.workspace.canUpdate();
        var actions = canUpdate ? [{name: 'create_job', target: chorus.dialogs.ConfigureJob}] : [];
        this.primaryActionPanel = new chorus.views.PrimaryActionPanel({actions: actions, pageModel: this.workspace});
    }
});
