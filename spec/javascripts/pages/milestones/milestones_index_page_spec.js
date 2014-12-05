describe("chorus.pages.MilestonesIndexPage", function () {
    beforeEach(function () {
        this.workspace = backboneFixtures.workspace();
        this.page = new chorus.pages.MilestonesIndexPage(this.workspace.id);
    });

    describe("subnav", function () {
        it("should create the subnav on the milestones tab", function () {
            expect(this.page.subNav).toBeA(chorus.views.SubNav);
        });
    });

    describe("#setup", function () {
        it("fetches the collection", function() {
            expect(this.page.collection).toHaveBeenFetched();
        });

        context("when the workspace fetch completes", function () {
            beforeEach(function () {
                this.server.completeFetchFor(this.workspace);
            });

            it("has a titlebar", function() {
                expect(this.page.$(".page_sub_header")).toContainText(this.workspace.name());
            });
        });
    });

    describe("#render", function () {
        beforeEach(function () {
            this.page.render();
        });

        describe("when the collection is loaded", function () {
            beforeEach(function () {
                this.milestones = backboneFixtures.milestoneSet();
                spyOn(this.page.collection, 'fetch');
                this.server.completeFetchFor(this.page.collection, this.milestones.models);
                this.server.completeFetchFor(this.workspace);
            });

            it("renders each milestone", function () {
                this.milestones.each(function (milestone) {
                    expect(this.page.$el).toContainText(milestone.get('name'));
                }, this);
            });

            describe("when invalidated is triggered on the model", function () {
                it("refetches the model", function () {
                    this.page.collection.trigger('invalidated');
                    expect(this.page.collection.fetch).toHaveBeenCalled();
                });
            });

            itBehavesLike.aPageWithPrimaryActions([
                {name: 'create_milestone', target: chorus.dialogs.ConfigureMilestone}
            ]);


            describe("if the user cannot update the workspace", function () {
                beforeEach(function () {
                    this.page.workspace.set({permission: ['read']});
                    this.page.render();
                });

                itBehavesLike.aPageWithPrimaryActions([]);
            });

            describe("if the workspace is archived", function () {
                beforeEach(function () {
                    this.page.workspace.set({archivedAt: "2012-05-08 21:40:14"});
                    this.page.render();
                });

                itBehavesLike.aPageWithPrimaryActions([]);
            });
        });

        describe("when fetching the collection is forbidden", function () {
            beforeEach(function () {
                spyOn(Backbone.history, "loadUrl");
                this.server.lastFetchFor(this.page.collection).failForbidden({license: "NOT_LICENSED"});
            });

            it("routes to the not licensed page", function() {
                expect(Backbone.history.loadUrl).toHaveBeenCalledWith("/notLicensed");
            });
        });
    });
});
