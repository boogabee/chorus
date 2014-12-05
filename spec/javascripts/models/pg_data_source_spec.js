describe("chorus.models.PgDataSource", function() {
    beforeEach(function () {
        this.dataSource = backboneFixtures.pgDataSource({id: 1});
    });

    it("has the right entity type", function () {
        expect(this.dataSource.entityType).toBe("pg_data_source");
    });

    it("has the right show url", function () {
        expect(this.dataSource.showUrl()).toBe("#/data_sources/1/databases");
    });

    it("has the right url", function () {
        expect(this.dataSource.url()).toContain('/data_sources/1');

        this.dataSource.unset("id", { silent: true });
        expect(this.dataSource.url()).toBe('/data_sources/');
    });

    describe("#databases", function () {
        beforeEach(function () {
            this.databases = this.dataSource.databases();
        });

        it("returns an DatabaseSet", function () {
            expect(this.databases).toBeA(chorus.collections.DatabaseSet);
        });

        it('sets the data source id', function () {
            expect(this.databases.attributes.dataSourceId).toBe(this.dataSource.get('id'));
        });

        it("memoizes", function () {
            expect(this.databases).toBe(this.dataSource.databases());
        });
    });
});
