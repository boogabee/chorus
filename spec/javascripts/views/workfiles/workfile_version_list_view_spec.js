describe("chorus.views.WorkfileVersionList", function() {
    beforeEach(function() {
        var version2attributes = backboneFixtures.workfileVersion({
            versionInfo: {
                modifier: {firstName: 'Bob', lastName: 'Doe'},
                id: 1,
                versionNum: 2,
                updatedAt: '2012-11-29T10:00:00Z'
            }
        }).attributes;

        var version1attributes = backboneFixtures.workfileVersion({
            versionInfo: {
                modifier: {firstName: 'Rob', lastName: 'Doe'},
                versionNum: 1,
                id: 2,
                updatedAt: '2011-11-29T10:00:00Z'
            }
        }).attributes;

        this.collection = new chorus.collections.WorkfileVersionSet([version1attributes, version2attributes]);
        this.view = new chorus.views.WorkfileVersionList({ collection: this.collection });
        this.view.render();
    });

    it("renders an li for each workfile version", function() {
        expect(this.view.$("li").length).toBe(2);
    });

    it("displays the delete link when user is a member of the workspace", function () {
        expect(this.view.$("li:eq(0) .delete_link")).toExist();
    });

    it("displays the version number for each item", function() {
        expect(this.view.$("li:eq(0) .version_title")).toContainTranslation("workfile.version_title", {versionNum: 2});
        expect(this.view.$("li:eq(1) .version_title")).toContainTranslation("workfile.version_title", {versionNum: 1});
    });

    it("has the versionId and versionNum as data attributes on the delete link", function () {
        expect(this.view.$("li:eq(0) .delete_link").data("versionId")).toBe(1);
        expect(this.view.$("li:eq(0) .delete_link").data("versionNumber")).toBe(2);
    });


    it("displays the author and date for each item", function() {
        expect(this.view.$("li:eq(0) .version_details")).toContainTranslation("workfile.version_saved_by", {
            authorName: "Bob Doe",
            formattedDate: "November 29, 2012"
        });

        expect(this.view.$("li:eq(1) .version_details")).toContainTranslation("workfile.version_saved_by", {
            authorName: "Rob Doe",
            formattedDate: "November 29, 2011"
        });
    });

    context("when the workspace is archived", function () {
        beforeEach(function () {
            this.view.collection.each(function(model) {
                model.workspace().set({archivedAt: "archivedDate"});
            });
            this.view.render();
        });
        it("does not display the delete link", function () {
            expect(this.view.$("li:eq(0) .delete_link")).not.toExist();
        });
    });

    context("when user does not have admin or update permission in the workspace", function () {
        beforeEach(function () {
            this.view.collection.each(function(model) {
                model.workspace().set({permission: ["read", "commenting"]});
            });
            this.view.render();
        });

        it("does not display the delete link", function () {
            expect(this.view.$("li:eq(0) .delete_link")).not.toExist();

        });
    });

    describe("clicking a version link", function() {
        it("triggers version changed page event", function() {
            this.workfileVersionChangedSpy = jasmine.createSpy();
            chorus.PageEvents.on("workfileVersion:changed", this.workfileVersionChangedSpy);

            this.view.$("a.version_link:eq(1)").click();
            expect(this.workfileVersionChangedSpy).toHaveBeenCalledWith(2);
        });
    });
});
