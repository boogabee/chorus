describe("chorus.collections.DatabaseColumnSet", function() {
    describe("database table column", function() {
        beforeEach(function() {
            var table = backboneFixtures.workspaceDataset.datasetTable({
                schema: {name: 'schema1'},
                objectName: 'table1',
                id: '1'
            });
            this.columns = table.columns();
        });

        it("has the correct urlTemplate", function() {
            expect(this.columns.url()).toContain("/datasets/1/columns");
        });

        describe("when a model is added", function() {
            it("sets the dataset on the added column", function() {
                this.columns.add(backboneFixtures.databaseColumnSet().at(0));
                expect(this.columns.models[0].dataset).toBe(this.columns.dataset);
            });
        });
    });

    describe("database view column", function() {
        beforeEach(function() {
            var view = backboneFixtures.workspaceDataset.datasetView({
                schema: {name: 'schema1'},
                objectName: 'view1',
                id: '3'
            });
            this.columns = view.columns();
        });

        it("has the correct urlTemplate", function() {
            expect(this.columns.url()).toContain("/datasets/3/columns");
        });

        context("when the names need to be url encoded", function() {
            beforeEach(function() {
                var table = backboneFixtures.workspaceDataset.datasetView({
                    schema: {name: 'baz'},
                    objectName: '!!!',
                    id: '4'
                });
                this.columns = table.columns();
            });

            it("should url encode the appropriate entities", function() {
                expect(this.columns.url()).toContain("/datasets/4/columns");
            });
        });

    });

    describe("database chorus view column", function() {
        beforeEach(function() {
            var chorusView = backboneFixtures.workspaceDataset.chorusView({
                workspace: {
                    id: '10'
                },
                id: '5'
            });
            this.columns = chorusView.columns();
        });

        it("has the correct urlTemplate", function() {
            expect(this.columns.url()).toMatchUrl('/datasets/5/columns', {paramsToIgnore: ['page', 'per_page']});
        });
    });

    describe("#urlParams", function() {
        context("when type attribute is meta", function() {
            beforeEach(function() {
                this.columns = backboneFixtures.workspaceDataset.datasetView().columns({type: "meta"});
            });

            it("should include the 'type' parameter in the url", function() {
                expect(this.columns.urlParams().type).toBe("meta");
            });
        });

        context("when type attribute is unspecified", function() {
            beforeEach(function() {
                this.columns = backboneFixtures.workspaceDataset.datasetView().columns();
            });

            it("should not include the 'type' parameter in the url", function() {
                expect(this.columns.urlParams().type).toBeFalsy();
            });
        });
    });
});
