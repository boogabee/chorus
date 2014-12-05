describe("chorus.views.JobQuickstart", function () {
    beforeEach(function () {
        this.job = backboneFixtures.job({tasks: []});
        chorus.page = {};
        chorus.page.workspace = this.job.workspace();

        this.view = new chorus.views.JobQuickstart({model: this.job });

        this.modalSpy = stubModals();
        this.view.render();
    });

    describe("the quick launchers", function() {
        itBehavesLike.aDialogLauncher('a.new_import_source_data.dialog', chorus.dialogs.ConfigureImportSourceDataTask);
        itBehavesLike.aDialogLauncher('a.new_run_work_flow.dialog', chorus.dialogs.ConfigureWorkfileTask);
        itBehavesLike.aDialogLauncher('a.new_run_sql.dialog', chorus.dialogs.ConfigureWorkfileTask);
    });

});
