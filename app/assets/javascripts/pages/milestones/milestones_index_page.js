chorus.pages.MilestonesIndexPage = chorus.pages.Base.extend({
    constructorName: 'MilestonesIndexPage',

    setup: function (workspaceId) {
        this.subNav = new chorus.views.SubNav({workspace: this.workspace, tab: "milestones"});

        this.collection = new chorus.collections.MilestoneSet([], {workspaceId: workspaceId});
        this.handleFetchErrorsFor(this.collection);
        this.collection.fetch();

        this.mainContent = new chorus.views.MainContentList(this.listConfig());

        this.subscribePageEvent("milestone:selected", this.milestoneSelected);
        this.listenTo(this.collection, "invalidated", function () { this.collection.fetch(); });

        this.requiredResources.add(this.workspace);
    },

    preRender: function () {
        this.buildPrimaryActionPanel();
    },

    makeModel: function(workspaceId) {
        this.loadWorkspace(workspaceId);
    },

    milestoneSelected: function (milestone) {
        if (this.sidebar) this.sidebar.teardown(true);

        this.sidebar = new chorus.views.MilestoneSidebar({model: milestone});
        this.renderSubview('sidebar');
    },

    listConfig: function () {
        return {
            modelClass: "Milestone",
            collection: this.collection
        };
    },

    buildPrimaryActionPanel: function () {
        var canUpdate = this.workspace.isActive() && this.workspace.canUpdate();
        var actions = canUpdate ? [ {name: 'create_milestone', target: chorus.dialogs.ConfigureMilestone} ] : [];
        this.primaryActionPanel = new chorus.views.PrimaryActionPanel({actions: actions, pageModel: this.workspace});
    }

});
