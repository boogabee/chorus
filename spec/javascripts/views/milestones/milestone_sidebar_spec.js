describe("chorus.views.MilestoneSidebar", function () {
    beforeEach(function () {
        this.milestone = backboneFixtures.milestoneSet().first();
        this.view = new chorus.views.MilestoneSidebar({model: this.milestone});
        this.modalSpy = stubModals();
        this.view.render();
    });

    context("when the user has workspace permissions", function () {
        beforeEach(function () {
            spyOn(this.milestone.workspace(), 'canUpdate').andReturn(true);
            this.view.render();
        });

        describe("clicking 'Delete Milestone'", function () {
            itBehavesLike.aDialogLauncher("a.delete_milestone", chorus.alerts.MilestoneDelete);
        });

        describe('milestone state toggle', function () {
            context('the milestone is "planned"', function () {
                beforeEach(function () {
                    this.milestone.set('state', 'planned');
                    this.view.render();
                });

                it("displays a 'complete' link", function () {
                    expect(this.view.$('.toggle_state')).toContainTranslation('milestone.actions.toggle.planned');
                });

                describe("clicking the link", function () {
                    beforeEach(function () {
                        spyOn(this.milestone, "toggleState");
                        this.view.$('.toggle_state').click();
                    });

                    it("toggles the state", function () {
                        expect(this.milestone.toggleState).toHaveBeenCalled();
                    });
                });
            });

            context('the milestone is "achieved"', function () {
                beforeEach(function () {
                    this.milestone.set('state', 'achieved');
                    this.view.render();
                });

                it("displays a 'restart' link", function () {
                    expect(this.view.$('.toggle_state')).toContainTranslation('milestone.actions.toggle.achieved');
                });
            });
        });
    });

    context("when the user does not have workspace permissions", function () {
        beforeEach(function () {
            spyOn(this.milestone.workspace(), 'canUpdate').andReturn(false);
            this.view.render();
        });

        it("should not display the edit/delete links", function () {
            expect(this.view.$('.actions a')).not.toExist();
        });
    });
});
