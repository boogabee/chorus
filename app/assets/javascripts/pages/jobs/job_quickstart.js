chorus.views.JobQuickstart = chorus.views.Base.extend({
    constructorName: "JobQuickstartView",
    templateName: "job_quickstart",
    additionalClass: "job_show quickstart",

    events: {
        'click a.new_import_source_data.dialog': 'launchCreateImportSourceDataTaskDialog',
        'click a.new_run_sql.dialog': 'launchCreateSqlTaskDialog',
        'click a.new_run_work_flow.dialog': 'launchCreateFlowTaskDialog'
    },

    launchCreateImportSourceDataTaskDialog: function (e) {
        e && e.preventDefault();
        new chorus.dialogs.ConfigureImportSourceDataTask({job: this.model}).launchModal();
    },

    launchCreateSqlTaskDialog: function(e) {
        e && e.preventDefault();
        this.launchWorkfilePicker('sql');
    },

    launchCreateFlowTaskDialog: function(e) {
        e && e.preventDefault();
        this.launchWorkfilePicker('work_flow');
    },

    launchWorkfilePicker: function(fileType) {
        var workFlows = new chorus.collections.WorkfileSet([], {fileType: fileType, workspaceId: this.model.workspace().get("id")});
        new chorus.dialogs.ConfigureWorkfileTask({job: this.model, collection: workFlows}).launchModal();
    }
});
