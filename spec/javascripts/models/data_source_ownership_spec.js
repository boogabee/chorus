describe("chorus.models.DataSourceOwnership", function() {
    beforeEach(function() {
        this.model = new chorus.models.DataSourceOwnership({dataSourceId: 1, user_id: 2});
    });

    it("has a valid url", function() {
        expect(this.model.url()).toBe("/data_sources/1/owner");
    });

    it("wraps parameters in 'owner'", function() {
        expect(this.model.parameterWrapper).toBe("owner");
    });
});
