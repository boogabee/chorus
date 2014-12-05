describe("chorus.alerts.JobDelete", function () {
    beforeEach(function () {
        var task = backboneFixtures.job().tasks().at(0);
        this.alert = new chorus.alerts.JobTaskDelete({model: task});
        this.alert.launchModal();
    });

    describe("submitting the dialog", function () {
        beforeEach(function () {
            spyOn(chorus.router, 'navigate');
        });

        it("redirects to the Jobs index page", function () {
            this.alert.model.destroy();
            this.server.lastDestroyFor(this.alert.model).succeed();

            var job = this.alert.model.job();
            var workspace = job.workspace();
            var deletePath = '/workspaces/' + workspace.get('id') + '/jobs/' + job.get("id");

            expect(chorus.router.navigate).toHaveBeenCalledWith(deletePath);
        });
    });
});