describe("chorus.collections.WorkfileSet", function () {
    beforeEach(function () {
        this.workspace = new chorus.models.Workspace({id: 1234});
        this.collection = new chorus.collections.WorkfileSet([
            backboneFixtures.workfile.sql({workspace: {id: this.workspace.id}}),
            backboneFixtures.workfile.sql({workspace: {id: this.workspace.id}})
        ], {workspaceId: this.workspace.id});
    });

    it("extends chorus.collections.LastFetchWins", function() {
        expect(this.collection).toBeA(chorus.collections.LastFetchWins);
    });

    describe("#fetch", function () {
        describe("without filtering", function () {
            it("creates the right URL", function () {
                expect(this.collection.url()).toBe("/workspaces/1234/workfiles?page=1&per_page=20");
            });
        });
        describe("with filtering", function () {
            beforeEach(function () {
                this.collection.attributes.fileType = "sql";
            });
            it("it has correct Url", function () {
                expect(this.collection.url()).toBe("/workspaces/1234/workfiles?file_type=sql&page=1&per_page=20");
            });
        });
        describe("with sorting", function () {
            beforeEach(function () {
                this.collection.attributes.fileType = "sql";
                this.collection.sortAsc("name");
            });
            it("it has correct Url", function () {
                expect(this.collection.url()).toBe("/workspaces/1234/workfiles?file_type=sql&page=1&per_page=20&order=name");
            });
        });
    });

    describe("#search", function () {
        beforeEach(function () {
            this.collection.attributes.fileType = "work_flow";
        });

        it("triggers an API query for the given term", function () {
            this.collection.search("search term");
            var url = this.server.lastFetchFor(this.collection).url;

            expect(url).toHaveUrlPath("/workspaces/" + this.workspace.id + "/workfiles");
            expect(url).toContainQueryParams({name_pattern: "search term", file_type: this.collection.fileType});
        });

        it("triggers 'searched' when API query returns", function () {
            var eventListener = jasmine.createSpy();
            this.collection.bind('searched', eventListener);
            this.collection.search("search term");
            this.server.completeFetchFor(this.collection, []);
            expect(eventListener).toHaveBeenCalled();
        });
    });

    describe("#destroy", function () {
        beforeEach(function() {
            this.workfileIds = this.collection.pluck('id');
            this.collection.destroy();
        });

        it("deletes the models in bulk", function() {
            var req = this.server.lastDestroy();

            expect(req.url).toHaveUrlPath("/workspaces/" + this.workspace.id + "/workfiles");
            expect(req.json()['workfile_ids']).toEqual(this.workfileIds);
        });
    });
});
