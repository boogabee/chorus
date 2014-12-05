describe("chorus.views.JobTaskSidebar", function () {
    beforeEach(function () {
        this.job = backboneFixtures.job();
        this.task = this.job.tasks().at(0);
        this.view = new chorus.views.JobTaskSidebar({model: this.task});
        this.modalSpy = stubModals();
        this.view.render();
    });

    context("when the user has workspace permissions", function () {
        beforeEach(function () {
            spyOn(this.task.job().workspace(), 'canUpdate').andReturn(true);
            this.view.render();
        });

        describe("clicking 'Delete Job Task'", function () {
            itBehavesLike.aDialogLauncher("a.delete_job_task", chorus.alerts.JobTaskDelete);
        });

        describe("clicking 'Edit Job Task'", function () {
            context("when a RunWorkFlow task is selected", function () {
                beforeEach(function () {
                    this.task.set('action', 'run_work_flow');
                });
                itBehavesLike.aDialogLauncher("a.edit_job_task", chorus.dialogs.ConfigureWorkfileTask);
            });

            context("when a RunWorkFlow task is selected", function () {
                beforeEach(function () {
                    this.task.set('action', 'run_sql_workfile');
                });
                itBehavesLike.aDialogLauncher("a.edit_job_task", chorus.dialogs.ConfigureWorkfileTask);
            });

            context("when an Import task is selected", function () {
                beforeEach(function () {
                    chorus.page = {};
                    chorus.page.workspace = this.job.workspace();
                    this.task.set('action', 'import_source_data');
                });

                itBehavesLike.aDialogLauncher("a.edit_job_task", chorus.dialogs.ConfigureImportSourceDataTask);
            });
        });
    });

    context("when the user does not have workspace permissions", function () {
        beforeEach(function () {
            spyOn(this.task.job().workspace(), 'canUpdate').andReturn(false);
            this.view.render();
        });

        it("should not display the edit/delete links", function () {
            expect(this.view.$('.actions a')).not.toExist();
        });
    });


});
