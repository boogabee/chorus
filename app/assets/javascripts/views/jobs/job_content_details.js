chorus.views.JobContentDetails = chorus.views.Base.extend({
    templateName: "job_content_details",
    constructorName: 'JobContentDetails',

    events: {
        "click button.toggle_enabled": "toggleEnabled",
        "click button.edit_schedule": "launchEditDialog",
        "click button.run_job": "runJob"
    },

    createActions: [
        {className: 'import_source_data', text: t("job_task.action.import_source_data")},
        {className: 'run_sql_workfile', text: t("job_task.action.run_sql_workfile")},
        {className: 'run_work_flow', text: t("job_task.action.run_work_flow")}
    ],

    menuEvents: {
        "a.import_source_data": function(e) {
            this.launchCreateImportSourceDataTaskDialog(e);
        },
        "a.run_work_flow": function(e) {
            this.launchCreateFlowTaskDialog(e, 'work_flow');
        },
        "a.run_sql_workfile": function(e) {
            this.launchCreateFlowTaskDialog(e, 'sql');
        }
    },

    setup: function() {
        this.model.fetchIfNotLoaded();
        this.workspace = this.model.workspace();
    },

    postRender: function () {
        this.menu(this.$(".create_task"), {
            content: this.$(".create_task_menu"),
            orientation: "right",
            contentEvents: this.menuEvents
        });
    },

    launchCreateFlowTaskDialog: function(e, workfileFilter) {
        e && e.preventDefault();
        var workfileSet = new chorus.collections.WorkfileSet([], {fileType: workfileFilter, workspaceId: this.model.workspace().get("id")});
        new chorus.dialogs.ConfigureWorkfileTask({job: this.model, collection: workfileSet}).launchModal();
    },

    launchCreateImportSourceDataTaskDialog: function (e) {
        e && e.preventDefault();
        new chorus.dialogs.ConfigureImportSourceDataTask({job: this.model}).launchModal();
    },

    launchEditDialog: function (e) {
        e && e.preventDefault();
        new chorus.dialogs.ConfigureJob({model: this.model}).launchModal();
    },

    toggleEnabled: function () {
        this.$("button.toggle_enabled").text(t("job.actions.saving")).prop("disabled", true);
        this.model.toggleEnabled({unprocessableEntity: _.bind(this.launchEditDialog, this)});
    },

    runJob: function () {
        this.$('button.run_job').prop('disabled', true);
        this.model.run();
    },

    additionalContext: function() {
        return {
            canUpdate: this.canUpdate(),
            enabledButtonLabel: this.enabledButtonLabel(),
            actionBarClass: this.actionBarClass(),
            createActions: this.createActions,
            ableToRun: this.model.ableToRun(),
            runsOnDemand: this.model.runsOnDemand()
        };
    },

    canUpdate: function() {
        return this.workspace.canUpdate() && this.workspace.isActive();
    },

    enabledButtonLabel: function () {
        return this.model.get("enabled") ? 'job.actions.disable' : 'job.actions.enable';
    },

    actionBarClass: function () {
        return (this.model.get("enabled") || this.model.runsOnDemand()) ? 'action_bar_highlighted' : 'action_bar_limited';
    }
});
