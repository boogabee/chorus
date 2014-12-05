describe("chorus.views.ProjectStatusView", function() {
    beforeEach(function() {
        this.modalSpy = stubModals();
        this.model = backboneFixtures.project({ id : 4 });
        this.model.fetch();
        this.view = new chorus.views.ProjectStatus({ model : this.model });
        this.qtip = stubQtip();
        this.view.render();
    });

    itBehavesLike.aDialogLauncher("a.edit_project_status", chorus.dialogs.EditProjectStatus);

    describe("project status", function () {
        describe("reason", function () {
            beforeEach(function () {
                this.view.$('.status_reason').mouseover();
            });

            it("displays the most recent status change activity in a tooltip", function () {
                expect(this.qtip.$('.activity_item')).toContainText(this.model.get('projectStatusReason'));
            });

            it("omits the comment link", function () {
                expect(this.qtip.$('.activity_item')).not.toContainText('Comment');
            });
        });

        it("is set as a class on the edit link, so it can be colored", function () {
            expect(this.view.$('a.edit_project_status')).toHaveClass(this.model.get('projectStatus'));
        });
    });

    describe("milestones progress", function () {
        it("shows milestone progress as the width of progress bar", function () {
            expect(this.view.$('.progress').width()).toBe(this.model.milestoneProgress());
        });

        it("displays the ratio of milestones completed to milestones", function () {
            var completed = this.model.get('milestoneCompletedCount');
            var total = this.model.get('milestoneCount');

            expect(this.view.$('.ratio')).toContainText(completed + ' / ' + total);
        });

        it("links the ratio to the milestones list", function () {
            expect(this.view.$('.ratio').attr('href')).toEqual(this.model.milestonesUrl());
        });
    });

    describe("target date", function () {
        context("when the project has milestones", function () {
            beforeEach(function () {
                this.time = new Date(this.model.get('projectTargetDate')).addDays(-1).getTime();
                this.useFakeTimers(this.time);
                this.view.render();
            });

            it("is shown", function () {
                expect(this.view.$('.target_date')).toContainText("Target: in 1 day");
            });
        });

        context("when the project has no milestones", function () {
            beforeEach(function () {
                this.model.set('projectTargetDate', null);
            });

            it("displays filler copy", function () {
                expect(this.view.$('.target_date')).toContainTranslation('workspace.project.target.none_set');
            });
        });
    });

    describe("when milestone tracking is not enabled", function () {
        beforeEach(function () {
            spyOn(chorus.models.Config.instance().license(), 'limitMilestones').andReturn(true);
            this.view.render();
        });

        it("does not display the milestone elements", function() {
            expect(this.view.$(".milestones")).not.toExist();
        });
    });
});
