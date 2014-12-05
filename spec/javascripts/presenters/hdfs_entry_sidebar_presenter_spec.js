describe("chorus.presenters.HdfsEntrySidebar", function() {
    beforeEach(function() {
        this.model = backboneFixtures.hdfsFile();
        this.presenter = new chorus.presenters.HdfsEntrySidebar(this.model, {});
    });

    context("when the resource is null", function() {
        _.each([ "entityId", "fileName", "lastUpdatedStamp", "canCreateExternalTable" ], function(functionName) {
            it("does not raise an error for " + functionName, function() {
                this.presenter = new chorus.presenters.HdfsEntrySidebar(null, {});
                expect(_.bind(function() {
                    this.presenter[functionName]();
                }, this)).not.toThrow();
            });
        });
    });

    describe("entityId", function() {
        it("returns the id of the resource", function() {
            expect(this.presenter.entityId()).toBe(this.model.id);
        });
    });

    describe("fileName", function() {
        it("returns the name of the resource", function() {
            expect(this.presenter.fileName()).toBe(this.model.get("name"));
        });
    });

    describe("canCreateExternalTable", function() {
        context("when the resource is loaded, non-binary, and has no errors", function() {
            beforeEach(function() {
                this.model.loaded = true;
                this.model.set("isBinary", false);
                this.model.serverErrors = undefined;
            });

            it("returns true", function() {
                expect(this.presenter.canCreateExternalTable()).toBeTruthy();
            });
        });

        context("when the resource is not loaded", function() {
            it("returns false", function() {
                this.model.loaded = false;
                expect(this.presenter.canCreateExternalTable()).toBeFalsy();
            });
        });

        context("when the resource is binary", function() {
            it("returns false", function() {
                this.model.set("isBinary", true);
                expect(this.presenter.canCreateExternalTable()).toBeFalsy();
            });
        });

        context("when the resource has server errors", function() {
            it("returns false", function() {
                this.model.serverErrors = {bad: "really bad"};
                expect(this.presenter.canCreateExternalTable()).toBeFalsy();
            });
        });
    });

    describe("lastUpdatedStamp", function() {
        it("returns a formatted timestamp", function() {
            var lastUpdated = "2013-06-21T22:00:58Z";
            this.model.set("lastUpdatedStamp", lastUpdated);
            expect(this.presenter.lastUpdatedStamp()).toEqual(t("hdfs.last_updated", {when: Handlebars.helpers.relativeTimestamp(lastUpdated)}));
        });
    });
});