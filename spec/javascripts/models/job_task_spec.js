describe("chorus.models.JobTask", function () {
    beforeEach(function () {
        this.task = backboneFixtures.job().tasks().at(0);
    });

    describe("#job", function() {
        it("is a chorus.models.Job when it has a job", function() {
            this.task.set({job: backboneFixtures.jobJson()});
            expect(this.task.job()).toBeA(chorus.models.Job);
        });

        it("memoizes", function() {
            this.task.set({job: backboneFixtures.jobJson()});
            expect(this.task.job()).toEqual(this.task.job());
        });
    });

    describe("url", function () {
        it("includes workspace & job", function () {
            expect(this.task.url()).toEqual('/workspaces/' + this.task.job().workspace().get("id") + '/jobs/' + this.task.job().id + '/job_tasks/' + this.task.id);
        });
    });
});