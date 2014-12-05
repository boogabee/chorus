describe("chorus.collections.PgGpDataSourceSet", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.PgGpDataSourceSet([
            backboneFixtures.gpdbDataSource({ name: "Gun_instance" }),
            backboneFixtures.gpdbDataSource({ name: "cat_instance" }),
            backboneFixtures.gpdbDataSource({ name: "Fat_instance" }),
            backboneFixtures.gpdbDataSource({ name: "egg_instance" }),
            backboneFixtures.pgDataSource({ name: "Dog_instance" })
        ]);
    });

    it("specifies an entity type when fetching", function() {
        expect(this.collection.urlParams()["entityType[]"]).toEqual(["gpdb_data_source", "pg_data_source"]);
    });

    it('sorts the data sources by name, case insensitively', function() {
        expect(this.collection.at(0).get("name")).toBe("cat_instance");
        expect(this.collection.at(1).get("name")).toBe("Dog_instance");
        expect(this.collection.at(2).get("name")).toBe("egg_instance");
        expect(this.collection.at(3).get("name")).toBe("Fat_instance");
        expect(this.collection.at(4).get("name")).toBe("Gun_instance");
    });

    it("maps the data source to the correct model type", function() {
        this.collection.reset([
            backboneFixtures.gpdbDataSource({ name: "gp_instance" }).attributes,
            backboneFixtures.pgDataSource({ name: "pg_instance" }).attributes
        ]);
        expect(this.collection.findWhere({name: "gp_instance"})).toBeA(chorus.models.GpdbDataSource);
        expect(this.collection.findWhere({name: "pg_instance"})).toBeA(chorus.models.PgDataSource);
    });
});
