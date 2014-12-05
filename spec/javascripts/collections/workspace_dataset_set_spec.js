describe("chorus.collections.WorkspaceDatasetSet", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.WorkspaceDatasetSet([], {workspaceId: 10000});
    });

    it("extends chorus.collections.LastFetchWins", function() {
        expect(this.collection).toBeA(chorus.collections.LastFetchWins);
    });

    describe("#url", function() {
        it("is correct", function() {
            expect(this.collection.url({per_page: 10, page: 1})).toMatchUrl("/workspaces/10000/datasets?per_page=10&page=1");
        });

        context("with filter type", function() {
            it("appends the filter type", function() {
                this.collection.attributes.type = "SOURCE_TABLE";
                expect(this.collection.url({per_page: 10, page: 1})).toContainQueryParams({entity_subtype: "SOURCE_TABLE", per_page: "10", page: "1"});
            });
        });

        context("with name pattern", function() {
            beforeEach(function() {
                this.collection.attributes.namePattern = "Foo";
            });

            it("appends the name pattern", function() {
                expect(this.collection.url({per_page: 10, page: 1})).toContainQueryParams({
                    namePattern: "Foo",
                    per_page: "10",
                    page: "1"
                });
            });
        });

        context("with lots of url params", function() {
            it("correctly builds the url", function() {
                this.collection.attributes.type = "SOURCE_TABLE";
                this.collection.attributes.objectType = "TABLE";
                this.collection.attributes.namePattern = "Foo";
                this.collection.attributes.allImportDestinations = true;
                this.collection.attributes.database = backboneFixtures.database({id: "123"});
                expect(this.collection.url({per_page: 10, page: 1})).toContainQueryParams({
                    entity_subtype: "SOURCE_TABLE",
                    namePattern: "Foo",
                    allImportDestinations: "true",
                    databaseId: "123",
                    per_page: "10",
                    page: "1"
                });
            });
        });
    });

    describe("save", function() {
        it("includes the datasetId params", function() {
            this.collection.add(backboneFixtures.workspaceDataset.datasetTable({id: 1234, objectName: 'second'}));
            this.collection.add(backboneFixtures.workspaceDataset.datasetTable({id: 5678, objectName: 'first'}));
            this.collection.save();

            var json = this.server.lastCreateFor(this.collection).json();
            expect(json['dataset_ids']).toEqual([5678, 1234]);
        });
    });

    describe("sorting", function() {
        context("without a sorting override", function() {
            beforeEach(function() {
                this.collection.add(backboneFixtures.workspaceDataset.datasetTable({objectName: 'zTable'}));
                this.collection.add(backboneFixtures.workspaceDataset.datasetTable({objectName: 'a_zTable'}));
                this.collection.add(backboneFixtures.workspaceDataset.datasetTable({objectName: 'aTable'}));
            });

            it("sorts by objectName without _", function() {
                expect(this.collection.at(0).get("objectName")).toBe("aTable");
                expect(this.collection.at(1).get("objectName")).toBe("a_zTable");
                expect(this.collection.at(2).get("objectName")).toBe("zTable");
            });
        });

        context("with a sorting override", function() {
            beforeEach(function() {
                this.collection = new chorus.collections.WorkspaceDatasetSet([], {workspaceId: 10000, unsorted: true});
                this.collection.add(backboneFixtures.workspaceDataset.datasetTable({objectName: 'zTable'}));
                this.collection.add(backboneFixtures.workspaceDataset.datasetTable({objectName: 'aTable'}));
            });

            it("does not sort", function() {
                expect(this.collection.at(0).get("objectName")).toBe("zTable");
                expect(this.collection.at(1).get("objectName")).toBe("aTable");
            });
        });
    });

    describe("#hasFilter", function() {
        describe("when there is a name filter", function() {
            beforeEach(function() {
                this.collection.attributes.namePattern = "foo";
            });

            it("should be true", function() {
                expect(this.collection.hasFilter()).toBeTruthy();
            });
        });

        describe("when there is a type filter", function() {
            beforeEach(function() {
                this.collection.attributes.type = "foo";
            });

            it("should be true", function() {
                expect(this.collection.hasFilter()).toBeTruthy();
            });
        });

        describe("when there is not name or type filter", function() {
            it("should be false", function() {
                expect(this.collection.hasFilter()).toBeFalsy();
            });

            context("when null", function() {
                beforeEach(function() {
                    this.collection.attributes.namePattern = null;
                    this.collection.attributes.type= null;
                });

                it("should be false", function() {
                    expect(this.collection.hasFilter()).toBeFalsy();
                });
            });

            context("when blank", function() {
                beforeEach(function() {
                    this.collection.attributes.namePattern = '';
                    this.collection.attributes.type= '';
                });

                it("should be false", function() {
                    expect(this.collection.hasFilter()).toBeFalsy();
                });
            });
        });
    });

    describe("#destroy", function () {
        beforeEach(function() {
            this.datasetIds = this.collection.pluck('id');
            this.collection.destroy();
        });

        it("deletes the models in bulk", function() {
            var req = this.server.lastDestroy();

            expect(req.url).toHaveUrlPath("/workspaces/10000/datasets");
            expect(req.json()['dataset_ids']).toEqual(this.datasetIds);
        });
    });
});
