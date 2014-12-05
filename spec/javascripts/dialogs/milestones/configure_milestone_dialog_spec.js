describe("chorus.dialogs.ConfigureMilestone", function () {
    beforeEach(function () {
        this.modalSpy = stubModals();

        this.milestonePlan = {
            name: 'Deliver Business Value'
        };

        spyOn(chorus.router, "navigate");

        this.workspace = backboneFixtures.workspace();
        this.dialog = new chorus.dialogs.ConfigureMilestone({pageModel: this.workspace});
        this.dialog.render();
    });

    it("has all the dialog pieces", function () {
        expect(this.dialog.title()).toMatchTranslation("milestone.dialog.title");
        expect(this.dialog.$('button.submit').text()).toMatchTranslation("milestone.dialog.submit");
        expect(this.dialog.$('button.cancel').text()).toMatchTranslation("actions.cancel");
    });

    it("has a disabled submit button", function () {
        expect(this.dialog.$('.submit')).not.toBeEnabled();
    });

    describe("with valid attributes", function () {
        beforeEach(function () {
            this.dialog.$('.name').val(this.milestonePlan.name).trigger('keyup');
        });

        it("enables the submit button", function () {
            expect(this.dialog.$('.submit')).toBeEnabled();
        });

        describe("submitting the form", function () {
            beforeEach(function () {
                this.dialog.$("form").submit();
            });

            it("posts the form elements to the API", function () {
                var request = this.server.lastCreateFor(this.dialog.model);
                expect(request.url).toContain("/workspaces/" + this.workspace.id + "/milestones");
                expect(request.json()['milestone']['name']).toEqual(this.milestonePlan.name);
                expect(request.json()['milestone']['target_date']).toEqual(this.dialog.targetDatePicker.getDate().toISOString());
            });

            context("when the save succeeds", function () {
                beforeEach(function () {
                    spyOn(this.dialog, "closeModal");
                    spyOn(chorus, "toast");
                    chorus.page = {};
                    chorus.page.collection = new chorus.collections.MilestoneSet();
                    spyOn(chorus.page.collection, "trigger");
                    this.server.lastCreate().succeed();
                });

                it("it should close the modal", function () {
                    expect(this.dialog.closeModal).toHaveBeenCalled();
                });

                it("should create a toast", function () {
                    expect(chorus.toast).toHaveBeenCalledWith('milestone.dialog.toast');
                });

                it("should trigger 'invalidate' on the page's collection", function () {
                    expect(chorus.page.collection.trigger).toHaveBeenCalledWith('invalidated');
                });
            });
        });
    });
});