describe("chorus.models.DashboardConfig", function () {
    beforeEach(function () {
        this.model = new chorus.models.DashboardConfig({userId: 1});
    });

    it("it has the correct url", function() {
        expect(this.model.url()).toMatchUrl('/users/1/dashboard_config');
    });
});
