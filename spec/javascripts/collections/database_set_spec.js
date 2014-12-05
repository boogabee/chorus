describe("chorus.collections.DatabaseSet", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.DatabaseSet([], {dataSourceId: 86});
    });

    it("has the right show url", function() {
        expect(this.collection.showUrl()).toMatchUrl("#/data_sources/86/databases");
    });

    it("fetches from the correct endpoint", function() {
        this.collection.fetch();
        var databaseSetFetch = this.server.lastFetchFor(this.collection);
        expect(databaseSetFetch.url).toContain('/data_sources/86/databases');
    });
});