describe("chorus.views.JobItem", function () {
    beforeEach(function() {
        this.modalSpy = stubModals();
        var jobSet = backboneFixtures.jobSet();
        this.model = jobSet.reject(function (job) {
            return job.get('intervalUnit') === 'on_demand';
        })[0];
        this.model.set('lastRun', '2011-11-08T18:06:51Z');
        this.model.set('nextRun', '2050-11-08T18:06:51Z');
        this.view = new chorus.views.JobItem({ model: this.model });
        this.view.render();
    });

    it("links the job's name to its show page", function() {
        expect(this.view.$("a.name")).toHaveText(this.model.get("name"));
        expect(this.view.$("a.name")).toHaveHref(this.model.showUrl());
    });

    context("when the job is enabled", function () {
        beforeEach(function () {
            this.model.set('enabled', true);
            this.view.render();
        });

        it("includes the enabled job icon", function() {
            expect(this.view.$("img")).toHaveAttr("src", "/images/jobs/job.png");
        });
    });

    describe("frequency", function () {
        context("when the Job is run on Demand", function () {
            beforeEach(function () {
                this.model.set('intervalUnit', 'on_demand');
            });

            it("displays the 'on demand' text", function () {
                expect(this.view.$(".frequency")).toContainTranslation("job.frequency.on_demand");
            });

            it("returns 'On Demand' if the job is 'idle'", function () {
                this.model.set('status', 'idle');
                expect(this.view.jobStateKey()).toEqual('on_demand');
            });

            it("returns 'running' if the job is 'running' or 'enqueued'", function () {
                this.model.set('status', 'enqueued');
                expect(this.view.jobStateKey()).toEqual('running');

                this.model.set('status', 'running');
                expect(this.view.jobStateKey()).toEqual('running');
            });

            it("includes the enabled job icon", function() {
                expect(this.view.$("img")).toHaveAttr("src", "/images/jobs/job.png");
            });
        });

        context("when the Job is run on a schedule", function () {
            var three, days;

            beforeEach(function () {
                three = 3;
                days = 'days';
                this.model.set('intervalValue', three);
                this.model.set('intervalUnit', days);
            });

            it("displays the schedule text", function () {
                var $frequency = this.view.$(".frequency");
                expect($frequency).toContainTranslation("job.frequency.on_schedule", {intervalValue: three, intervalUnit: days});
            });

            context("when the job is disabled", function () {
                beforeEach(function () {
                    this.model.set('enabled', false);
                    this.view.render();
                });

                it("includes the disabled job icon", function() {
                    expect(this.view.$("img")).toHaveAttr("src", "/images/jobs/job-disabled.png");
                });
            });
        });
    });

    it("includes the job's state", function () {
        expect(this.view.$(".state")).toContainTranslation("job.state." + this.view.jobStateKey());
    });

    describe("#jobStateKey", function () {
        it("returns 'scheduled' if the job is enabled and not running", function () {
            this.model.set('enabled', 'true');
            expect(this.view.jobStateKey()).toEqual('scheduled');
        });

        it("returns stopping if the status is stopping", function () {
            this.model.set('status', 'stopping');
            expect(this.view.jobStateKey()).toEqual('stopping');
        });

        it("returns 'running' if the job is 'running' or 'enqueued'", function () {
            this.model.set('status', 'enqueued');
            expect(this.view.jobStateKey()).toEqual('running');

            this.model.set('status', 'running');
            expect(this.view.jobStateKey()).toEqual('running');
        });
    });

    describe("last run", function () {
        context("when last_run is populated", function () {
            it("includes when the job was last run", function () {
                expect(this.view.$(".last_run")).toContainText('2011');
            });

            itBehavesLike.aDialogLauncher('a.last_run_date', chorus.dialogs.JobResultDetail);
            
            context("when the last run was a failure", function () {
                beforeEach(function () {
                    this.model.set('lastRunFailed', true);
                    this.view.render();
                });

                it("has (show errors)", function () {
                    expect(this.view.$('.last_run')).toContainTranslation('job.show_errors');
                });
            });

            context("when the last run was a success", function () {
                beforeEach(function () {
                    this.model.set('lastRunFailed', false);
                    this.view.render();
                });

                it("has (show details)", function () {
                    expect(this.view.$('.last_run')).toContainTranslation('job.show_details');
                });
            });
        });

        context("when last_run is empty", function () {
            beforeEach(function () {
                this.model.set('lastRun', null);
                this.view.render();
            });

            it("shows a dash", function () {
                expect(this.view.$(".last_run")).toContainText('-');
            });
        });

        context("when next_run is empty", function () {
            beforeEach(function () {
                this.model.set('nextRun', null);
                this.view.render();
            });

            it("shows a dash", function () {
                expect(this.view.$(".next_run")).not.toExist();
            });
        });
    });

    context("when next_run is populated", function () {
        it("includes when the job will be run next", function () {
            expect(this.view.$(".next_run")).toContainText('2050');
        });
    });

    describe("when the model received an 'invalidated' trigger", function() {
        beforeEach(function() {
            spyOn(this.model, "fetch");
        });

        it("reloads the model", function() {
            this.model.trigger("invalidated");
            expect(this.model.fetch).toHaveBeenCalled();
        });
    });
});