describe("chorus.pages.UserDashboardEditPage", function() {
    beforeEach(function() {
        this.page = new chorus.pages.UserDashboardEditPage("42");
    });

    describe("#setup", function() {
        it("fetches the dashboard config for the correct user", function() {
            expect(this.page.model).toBeA(chorus.models.DashboardConfig);
            expect(this.page.model).toHaveBeenFetched();
        });

        it("has a UserDashboardEditView for main content", function() {
            expect(this.page.mainContent).toBeA(chorus.views.UserDashboardEditView);
            expect(this.page.mainContent.model).toBe(this.page.model);
        });

        context("when the resource is forbidden", function() {
            beforeEach(function() {
                spyOn(Backbone.history, "loadUrl");
                this.server.lastFetchFor(this.page.model).failForbidden();
            });

            it("navigates to the forbidden page", function() {
                expect(Backbone.history.loadUrl).toHaveBeenCalledWith("/unauthorized");
            });
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.page.render();
        });

        it("has the sub-header", function() {
            expect(this.page.$(".page_sub_header")).toContainTranslation("user.dashboard_edit.title");
        });
    });
});
