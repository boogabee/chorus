describe("chorus.views.SubNav", function() {
    beforeEach(function() {
        this.model = backboneFixtures.workspace();
        this.view = new chorus.views.SubNav({ tab : "workfiles", model : this.model });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view.render();
        });

        it("renders the subnav tabs", function() {
            expect(this.view.$("li").length).toBe(5);
        });

        context("when milestone tracking is not enabled", function() {
            beforeEach(function () {
                spyOn(chorus.models.Config.instance().license(), 'limitMilestones').andReturn(true);
                this.view.render();
            });

            it("the milestones tab does not contain a link", function() {
                expect(this.view.$("li.milestones a")).not.toExist();
            });
        });

        context("when jobs are not enabled", function() {
            beforeEach(function () {
                spyOn(chorus.models.Config.instance().license(), 'limitJobs').andReturn(true);
                this.view.render();
            });

            it("the jobs tab does not contain a link", function() {
                expect(this.view.$("li.jobs a")).not.toExist();
            });
        });

        it("selects the correct tab", function() {
            expect(this.view.$("li.workfiles")).toHaveClass("selected");
        });
    });
});
