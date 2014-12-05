describe("chorus.alerts.DataSourceAccountDelete", function() {
    beforeEach(function() {
        this.dataSource = backboneFixtures.gpdbDataSource({ id: '456' });
        setLoggedInUser({ id: "1011" });
        this.alert = new chorus.alerts.DataSourceAccountDelete({ dataSource: this.dataSource });
    });

    it("does not have a redirect url", function() {
        expect(this.alert.redirectUrl).toBeUndefined();
    });

    describe("#makeModel", function() {
        it("gets the user account for the data source that is the current page model", function(){
            expect(this.alert.model.get("userId")).toBe("1011");
            expect(this.alert.model.get("dataSourceId")).toBe("456");
        });
    });

    describe("successful deletion", function() {
        beforeEach(function() {
            spyOn(chorus, "toast");
            this.alert.model.trigger("destroy", this.alert.model);
        });

        it("displays a toast message", function() {
            expect(chorus.toast).toHaveBeenCalledWith("data_sources.account.delete.toast", undefined);
            expect(chorus.toast.calls.count()).toBe(1);
        });
    });
});
