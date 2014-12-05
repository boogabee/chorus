describe("chorus.models.WorkspaceDataset", function() {
    beforeEach(function() {
        this.dataset = backboneFixtures.workspaceDataset.datasetTable({
            id: '1011',
            workspace: {
                id: "44"
            },
            schema: {
                database: {
                    dataSource: {id: "45" }
                }
            },
            objectType: "foo",
            objectName: "japanese_teas"
        });

        this.chorusView = backboneFixtures.workspaceDataset.chorusView({
            id: '1011',
            workspace: {
                id: "44"
            }
        });
    });

    describe("show url", function() {

        it("has the right showUrl", function() {
            expect(this.dataset.showUrl()).toMatchUrl('#/workspaces/44/datasets/1011');
        });

        context("when the dataset is a chorus view", function() {

            it("has the right showUrl", function() {
                expect(this.chorusView.showUrl()).toMatchUrl("#/workspaces/44/chorus_views/1011");
            });
        });
    });

    it("has the right url", function() {
        expect(this.dataset.url()).toMatchUrl('/workspaces/44/datasets/1011');
    });

    it("has the right download url", function() {
        expect(this.dataset.url({ download: true })).toMatchUrl('/datasets/1011/download.csv');
    });

    it("has the right chorus view url", function() {
        expect(this.chorusView.url({ method : "delete"})).toMatchUrl("/chorus_views/1011");
        expect(this.chorusView.url({ method : "update"})).toMatchUrl("/chorus_views/1011");
        var readUrl = this.chorusView.url({ method: "read"});
        expect(readUrl).toMatchUrl("/workspaces/44/datasets/1011");
    });

    describe("when the 'invalidated' event is triggered", function() {
        describe("when the dataset belongs to a collection", function() {
            beforeEach(function() {
                this.collection = new chorus.collections.WorkspaceDatasetSet();
                this.collection.add(this.dataset);
            });

            it("re-fetches itself, because the last comment might have changed", function() {
                this.dataset.trigger("invalidated");
                expect(this.dataset).toHaveBeenFetched();
            });
        });

        describe("when the dataset has no collection", function() {
            it("does not fetch anything", function() {
                var dataset = this.dataset;
                dataset.trigger("invalidated");
                expect(dataset).not.toHaveBeenFetched();
            });
        });
    });

    describe("#createDuplicateChorusView", function() {
        beforeEach(function() {
            this.model = backboneFixtures.workspaceDataset.chorusView();
            this.copy = this.model.createDuplicateChorusView();
        });

        it("returns a chorus view with the right data", function() {
            expect(this.copy).toBeA(chorus.models.ChorusView);
            expect(this.copy.get("objectName")).toMatchTranslation("dataset.chorusview.copy_name", { name: this.model.get("objectName") });

            expect(this.copy.get("workspace")).toBe(this.model.get("workspace"));
            expect(this.copy.get("workspace")).toBeDefined();

            expect(this.copy.get("sourceObjectId")).toBe(this.model.id);
            expect(this.copy.sourceObject).toBe(this.model);
            expect(this.copy.duplicate).toBeTruthy();
        });

        it("does not give the chorus view an id", function() {
            expect(this.copy.get("id")).toBeUndefined();
        });
    });

    describe("#statistics", function() {
        context("for a chorus view", function() {
            beforeEach(function() {
                this.dataset = this.chorusView;
            });

            it("sets the workspace info into the statistics object", function() {
                var workspace = this.dataset.statistics().get("workspace");
                expect(workspace).toEqual(this.dataset.get("workspace"));
            });

            it("sets the dataset id onto the statistics object as 'datasetId'", function() {
                expect(this.dataset.statistics().datasetId).toBe(this.dataset.get("id"));
            });
        });
    });

    describe("#activities", function() {
        context("for a chorus view", function() {
            beforeEach(function() {
                this.dataset = this.chorusView;
            });

            it("sets the workspace info into the ActivitySet object", function() {
                expect(this.dataset.activities().attributes.workspace).toEqual(this.dataset.get("workspace"));
            });
        });

        context("for a non-chorus view", function() {
            beforeEach(function() {
                this.dataset.set({ entitySubtype: "SANDBOX_TABLE" });
            });

            it("does not set the workspace info into the ActivitySet object", function() {
                expect(this.dataset.activities().attributes.workspace).toBeUndefined();
            });
        });
    });

    describe("#iconUrl", function() {
        context("when the user does not have credentials", function() {
            beforeEach(function() {
                this.dataset = backboneFixtures.workspaceDataset.datasetTable();
                this.unlockedIconUrl = this.dataset.iconUrl();
                this.dataset.set({hasCredentials: false});
            });

            it("has the locked version of the icon", function() {
                var lockedIconUrl = this.dataset.iconUrl();
                expect(lockedIconUrl).toBe(this.unlockedIconUrl.replace(".png", "_locked.png"));
            });
        });
    });

    describe("#columns", function() {
        it("returns a DatabaseColumnSet with a workspaceId", function() {
            expect((this.dataset).columns().attributes.workspaceId).toBe(this.dataset.get('workspace').id);
        });
    });

    describe("#getImports", function() {
        it("returns the imports for this dataset", function() {
            expect(this.dataset.getImports().attributes.datasetId).toBe(this.dataset.id);
            expect(this.dataset.getImports().attributes.workspaceId).toBe(this.dataset.get("workspace").id);
        });

        it("memoizes", function() {
            expect(this.dataset.getImports()).toBe(this.dataset.getImports());
        });
    });

    describe("#hasImport", function() {
        it("is false if there are no loaded imports", function() {
            spyOn(this.dataset, 'getImports').andReturn(new chorus.collections.WorkspaceImportSet());
            expect(this.dataset.hasImport()).toBeFalsy();
        });

        it("is true if there are imports", function() {
            this.dataset.getImports().add(backboneFixtures.workspaceImportSet().models);
            expect(this.dataset.hasImport()).toBeTruthy();
        });
    });

    describe("#lastImport", function() {
        it("is falsy when there are no imports", function() {
            expect(this.dataset.lastImport()).toBeFalsy();
        });

        it("returns the first import if there are more than one", function() {
            var imports = backboneFixtures.workspaceImportSet().models;
            this.dataset.getImports().add(imports);
            expect(imports.length).toBeGreaterThan(1);
            expect(this.dataset.lastImport()).toBe(_.first(imports));
        });
    });


    describe("#deriveChorusView", function() {
        beforeEach(function() {
            this.chorusView = this.dataset.deriveChorusView();
        });

        it("returns a chorus view", function() {
            expect(this.chorusView).toBeA(chorus.models.ChorusView);
        });

        it("has the right 'sourceObject'", function() {
            expect(this.chorusView.sourceObject).toBe(this.dataset);
        });

        it('sets the sourceObjectId', function() {
            expect(this.chorusView.get('sourceObjectId')).toBe(this.dataset.get('id'));
        });

        it('sets the sourceObjectType to dataset', function() {
            expect(this.chorusView.get("sourceObjectType")).toBe("dataset");
        });


        it("has the right data from the dataset", function() {
            expect(this.chorusView).toHaveAttrs({
                sourceObjectId: this.dataset.id,
                objectName: this.dataset.name()
            });
        });
    });

    describe("#hasOwnPage", function() {
        it("returns true", function() {
            expect(this.dataset.hasOwnPage()).toBeTruthy();
        });
    });

    describe("#lastImportSource", function() {
        context("when the dataset has been imported into (and has a 'importInfo' key)", function() {
            beforeEach(function() {
                this.dataset.set({ importInfo: {
                    completedStamp: "2012-02-29 14:35:38.165",
                    sourceId: '"10032"|"dca_demo"|"ddemo"|"TABLE"|"a2"',
                    sourceTable: "some_source_table"
                }});
                this.source = this.dataset.lastImportSource();
            });

            it("returns a dataset", function() {
                expect(this.source).toBeA(chorus.models.WorkspaceDataset);
            });

            it("has the right name, id and workspace id", function() {
                expect(this.source.get("id")).toBe('"10032"|"dca_demo"|"ddemo"|"TABLE"|"a2"');
                expect(this.source.get("workspaceId")).toBe(this.dataset.get("workspace").id);
                expect(this.source.get("objectName")).toBe("some_source_table");
            });
        });

        context("when the dataset has NOT been imported into", function() {
            it("returns undefined", function() {
                this.dataset.unset("importInfo");
                expect(this.dataset.lastImportSource()).toBeUndefined();
            });
        });
    });

    describe("#setWorkspace", function() {
        beforeEach(function() {
            this.newWorkspace = backboneFixtures.workspace();
            this.dataset.setWorkspace(this.newWorkspace);
        });

        it("should set the workspace object properly", function() {
            expect(this.dataset.get("workspace").id).toBe(this.newWorkspace.get("id"));
        });
    });

    describe("#useExternalLink", function() {
        it("returns false", function() {
            expect(this.dataset.useExternalLink()).toBeFalsy();
        });
    });
});
