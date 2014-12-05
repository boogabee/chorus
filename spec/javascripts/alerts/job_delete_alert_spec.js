describe("chorus.alerts.JobDelete", function () {
    beforeEach(function () {
        var job = backboneFixtures.job();
        this.alert = new chorus.alerts.JobDelete({model: job});
        this.alert.launchModal();
    });

    describe("submitting the dialog", function () {
        beforeEach(function () {
            spyOn(chorus.router, 'navigate');
        });

        it("redirects to the Jobs index page", function () {
            this.alert.model.destroy();
            this.server.lastDestroyFor(this.alert.model).succeed();

            expect(chorus.router.navigate).toHaveBeenCalledWith('#/workspaces/' +
                this.alert.model.workspace().get('id') + '/jobs');
        });
    });
});