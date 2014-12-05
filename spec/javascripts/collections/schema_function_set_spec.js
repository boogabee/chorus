describe("chorus.collections.SchemaFunctionSet", function() {
    beforeEach(function() {
        this.schema = backboneFixtures.schema();
        this.functionSet = this.schema.functions();
    });

    describe("#urlTemplate", function() {
        beforeEach(function() {
            this.schema = backboneFixtures.schema({name: "b/a/r", database: {name: "%foo%", dataSource: {id: 10000} }});
            this.functionSet = this.schema.functions();
        });

        it("encodes the url", function() {
            expect(this.functionSet.url()).toContain("/schemas/"+ this.schema.id +"/functions");
        });
    });

    describe("sort", function() {
        beforeEach(function() {
            this.functionSet = backboneFixtures.schemaFunctionSet();
        });

        it("sorts by functionName, case insensitive", function() {
            var functionNames = this.functionSet.pluck('name');
            expect(functionNames).toEqual(['foo', 'hello', 'ZOO']);
        });
    });
});
