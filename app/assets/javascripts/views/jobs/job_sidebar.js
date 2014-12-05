chorus.views.JobSidebar = chorus.views.Sidebar.extend({
    constructorName: "JobSidebar",
    templateName: "job_sidebar",

    subviews:{
        '.tab_control': 'tabs'
    },

    events: {
        "click a.disable": "disableJob",
        "click a.enable": "enableJob",
        'click a.edit_job': 'launchEditDialog',
        'click a.run_job': 'runJob',
        'click a.stop_job': 'stopJob',
        'click a.delete_job': 'launchDeleteAlert'
    },

    setup: function() {
        this.tabs = new chorus.views.TabControl(['activity']);
        this.registerSubView(this.tabs);
        this.createActivitiesTab();
    },

    createActivitiesTab: function() {
        var activities = this.model.activities();
        activities.fetch();

        this.tabs.activity = new chorus.views.ActivityList({
            collection: activities,
            additionalClass: "sidebar",
            displayStyle: ['without_workspace'],
            type: this.model.constructorName
        });
        this.tabs.registerSubView(this.tabs.activity);
    },

    disableJob: function(e) {
        e && e.preventDefault();
        this.model.disable();
    },

    enableJob: function(e) {
        e && e.preventDefault();
        this.model.enable({unprocessableEntity: _.bind(this.launchEditDialog, this)});
    },

    additionalContext: function () {
        return this.model ? {
            canUpdate: this.model.workspace().canUpdate(),
            enabled: this.model.get('enabled'),
            running: this.model.isRunning(),
            ableToRun: this.model.ableToRun(),
            runsOnDemand: this.model.runsOnDemand()
        } : {};
    },

    launchEditDialog: function (e) {
        e && e.preventDefault();
        new chorus.dialogs.ConfigureJob({model: this.model}).launchModal();
    },

    launchDeleteAlert: function (e) {
        e && e.preventDefault();
        new chorus.alerts.JobDelete({model: this.model}).launchModal();
    },

    runJob: function (e) {
        e && e.preventDefault();
        this.model.run();
    },

    stopJob: function (e) {
        e && e.preventDefault();
        this.model.stop();
    }
});
