describe("chorus.alerts.MultipleJobDelete", function () {
    beforeEach(function () {
        this.job = backboneFixtures.job();
        var jobs = new chorus.collections.JobSet([this.job, backboneFixtures.job({id: 'foo'}), backboneFixtures.job({id: 'bar'})]);
        this.alert = new chorus.alerts.MultipleJobDelete({collection: jobs});
        this.alert.launchModal();
    });

    describe("submitting the dialog", function () {
        beforeEach(function () {
            spyOn(chorus.router, 'navigate');
        });

        it("redirects to the Jobs index page", function () {
            this.alert.$("button.submit").click();

            expect(chorus.router.navigate).toHaveBeenCalledWith(this.job.workspace().jobsUrl());
        });
    });
});