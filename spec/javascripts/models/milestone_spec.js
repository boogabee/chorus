describe("chorus.models.Milestone", function () {
    beforeEach(function () {
        this.model = backboneFixtures.milestoneSet().first();
        spyOn(this.model, 'save');
    });

    describe("#toggleEnabled", function () {

        context("state is planned", function () {
            beforeEach(function () {
                this.model.set("state", 'planned');
                this.model.toggleState();
            });

            it("updates the state to achieved", function () {
                expect(this.model.save).toHaveBeenCalledWith({ state: 'achieved' }, { wait: true });
            });

        });

        context("state is planned", function () {
            beforeEach(function () {
                this.model.set("state", 'achieved');
                this.model.toggleState();
            });

            it("updates the state to planned", function () {
                expect(this.model.save).toHaveBeenCalledWith({ state: 'planned' }, { wait: true });
            });

        });
    });

});