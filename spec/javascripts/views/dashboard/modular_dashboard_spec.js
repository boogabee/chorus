describe("chorus.views.ModularDashboard", function() {
    beforeEach(function() {
        this.view = new chorus.views.ModularDashboard();
        this.fetchedModel = backboneFixtures.dashboardConfig();
        this.modules = this.fetchedModel.get("modules");
    });

    context("when the fetch completes", function () {
        beforeEach(function () {
            this.server.completeFetchFor(this.view.model, this.fetchedModel);
        });

        it("renders the appropriate number of subview placeholders", function () {
            expect(this.view.$('.dashboard_module').length).toBe(this.modules.length);
        });

        it("sets all of the subviews", function () {
            _.each(this.modules, function (moduleName, i) {
                expect(this.view['module' + i]).toBeA(chorus.views['Dashboard' + moduleName]);
            }, this);
        });
    });
});
