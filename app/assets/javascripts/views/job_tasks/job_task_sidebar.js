chorus.views.JobTaskSidebar = chorus.views.Sidebar.extend({
    constructorName: "JobTaskSidebar",
    templateName:"job_task_sidebar",

    events: {
        'click .delete_job_task': 'launchDeleteAlert',
        'click .edit_job_task': 'launchTaskConfigurationDialog'
    },

    additionalContext: function() {
        return {
            canUpdate: this.model.job().workspace().canUpdate()
        };
    },

    launchDeleteAlert: function (e) {
        e && e.preventDefault();
        new chorus.alerts.JobTaskDelete({model: this.model}).launchModal();
    },

    launchTaskConfigurationDialog: function (e) {
        e && e.preventDefault();
        var action = this.model.get('action');
        if (action === 'import_source_data') {
            new chorus.dialogs.ConfigureImportSourceDataTask({model: this.model}).launchModal();
        } else if (action === 'run_work_flow') {
            this.launchWorkfilePicker('work_flow');
        } else if (action === 'run_sql_workfile') {
            this.launchWorkfilePicker('sql');
        }
    },

    launchWorkfilePicker: function(fileType) {
        var workfiles = new chorus.collections.WorkfileSet([], {fileType: fileType, workspaceId: this.model.job().workspace().get("id")});
        new chorus.dialogs.ConfigureWorkfileTask({model: this.model, collection: workfiles}).launchModal();
    }
});
