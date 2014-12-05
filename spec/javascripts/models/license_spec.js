describe("chorus.models.License", function () {
    beforeEach(function () {
        this.model = backboneFixtures.license();
    });

    describe("#homePage", function() {
        context("when there is a homePage attr", function() {
            beforeEach(function () {
                this.model.set("homePage", "WorkspaceIndex");
            });

            it("it returns that value", function() {
                expect(this.model.homePage()).toBe("WorkspaceIndex");
            });
        });

        context("when there is not a homePage attr", function() {
            beforeEach(function () {
                this.model.set("homePage", null);
            });

            it("it returns Dashboard", function() {
                expect(this.model.homePage()).toBe("Dashboard");
            });
        });
    });

    describe("#applicationKey", function () {
        context("when vendor is alpine", function() {
            it("returns alpine_#{level}", function() {
                this.model.set("vendor", "alpine");
                this.model.set("level", "triple-platinum");
                expect(this.model.applicationKey()).toBe("alpine_triple-platinum");
            });
        });

        context("when vendor is not alpine", function() {
            it("returns vendor", function() {
                this.model.set("vendor", "openchorus");
                this.model.set("level", "triple-platinum");
                expect(this.model.applicationKey()).toBe("openchorus");
            });
        });
    });
});
