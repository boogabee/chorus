describe("chorus.pages.WorkspaceDatasetShowPage", function() {
    beforeEach(function() {
        this.workspace = backboneFixtures.workspace({
            id: '100',
            "sandboxInfo": {
                id: 6,
                name: "schema",
                database: { id: 4, name: "db", dataSource: { id: 5, name: "dataSource" } }
            }
        });
        chorus.page = {workspace: this.workspace};

        var sandboxInfo = this.workspace.sandbox();

        this.dataset = backboneFixtures.workspaceDataset.datasetTable({
            schema: {
                name: sandboxInfo.get("name"),
                database: {
                    name: sandboxInfo.database().name(),
                    dataSource: {
                        id: sandboxInfo.dataSource().id,
                        name: sandboxInfo.dataSource().name()
                    }
                }
            },
            objectName: 'tableName',
            workspace: { id: this.workspace.get("id") }
        });

        this.columnSet = this.dataset.columns();

        this.datasetId = this.dataset.get('id');

        this.page = new chorus.pages.WorkspaceDatasetShowPage(this.workspace.get("id").toString(), this.datasetId);
        spyOn(this.page, "drawColumns").andCallThrough();
    });

    it("has a helpId", function() {
        expect(this.page.helpId).toBe("dataset");
    });

    describe("#initialize", function() {
        it("sets the workspace id, for prioritizing search", function() {
            expect(this.page.workspaceId).toBe(100);
        });

        it("sets requiredResources in the sidebar", function() {
            expect(this.page.sidebarOptions.requiredResources[0].id).toBe(this.page.workspace.id);
        });

        it("sets the workspace to pass into contentDetails", function() {
            expect(this.page.contentDetailsOptions.workspace).toBe(this.page.workspace);
        });

        it("marks the workspace as a required resource", function() {
            expect(this.page.requiredResources.find(function(resource) {
                return resource instanceof chorus.models.Workspace && resource.get("id") === "100";
            }, this)).toBeTruthy();
        });

        context("when the workspace fetch completes", function() {
            beforeEach(function() {
                this.server.completeFetchFor(this.workspace);
            });

            it("has a titlebar", function() {
                expect(this.page.$(".page_sub_header")).toContainText(this.workspace.name());
            });

            it("constructs a dataset with the right id", function() {
                expect(this.page.model).toBeA(chorus.models.WorkspaceDataset);
                expect(this.page.model.get("id")).toBe(this.datasetId);
            });

            context("when the dataset fetch completes", function() {
                beforeEach(function() {
                    this.server.completeFetchFor(this.dataset);
                });

                describe("when the columnSet fetch completes", function() {
                    beforeEach(function() {
                        this.server.lastFetchAllFor(this.columnSet).succeed([
                            backboneFixtures.databaseColumn(),
                            backboneFixtures.databaseColumn()
                        ]);
                    });

                    it("stores a local copy of the columns in case a join is added when editing a ChorusView", function() {
                        expect(this.page.columnSet.models).toEqual(this.page.dataset.columns().models);
                        expect(this.page.columnSet).not.toEqual(this.page.dataset.columns());
                    });

                    it("does not modify the dataset reference the existing columns have", function() {
                        expect(this.page.columnSet.models[0].dataset).toBe(this.page.dataset);
                    });

                    it("sets the sidebar's workspace", function() {
                        expect(this.page.sidebar.options.workspace.id).toBe(this.page.workspace.id);
                    });

                    it("sets the contentDetail's workspace", function() {
                        expect(this.page.mainContent.contentDetails.options.workspace.id).toBe(this.page.workspace.id);
                    });
                });
            });
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.server.completeFetchFor(this.workspace);
            this.resizedSpy = spyOnEvent(this.page, 'resized');
            this.server.completeFetchFor(this.dataset);
            this.server.completeFetchAllFor(this.columnSet, [backboneFixtures.databaseColumn(), backboneFixtures.databaseColumn()]);
            this.server.completeFetchFor(this.dataset.statistics());
        });

        describe("sidebar", function() {
            it("sets workspace", function() {
                expect(this.page.sidebar.options.workspace).toBeTruthy();
            });

            describe("deriving a chorus view", function () {
                beforeEach(function () {
                    spyOn(this.page, 'constructSidebarForType');
                });

                it("shows the dataset_create_chorus_view_sidebar", function () {
                    this.page.$('.derive').click();
                    expect(this.page.constructSidebarForType).toHaveBeenCalledWith('chorus_view');
                });
            });

        });

        describe("#contentDetails", function() {
            it("has a Derive Chorus View button", function() {
                expect(this.page.$(".derive")).toExist();
            });
        });

        describe("#contentHeader", function() {
            describe("the links at the top", function() {
                it('includes the link to the data source', function() {
                    expect(this.page.$(".content_header a.data_source")).toHaveHref(this.page.model.dataSource().showUrl());
                    expect(this.page.$(".content_header a.data_source")).toHaveText(this.page.model.dataSource().name());
                });

                it("includes the link to the database", function() {
                    expect(this.page.$(".content_header a.database")).toHaveHref(this.page.model.database().showUrl());
                    expect(this.page.$(".content_header a.database")).toHaveText(this.page.model.database().name());
                });

                it("includes the link to the schema", function() {
                    expect(this.page.$(".content_header a.schema")).toHaveHref(this.page.model.schema().showUrl());
                    expect(this.page.$(".content_header a.schema")).toHaveText(this.page.model.schema().name());
                });
            });

            it("has a workspace id", function() {
                expect(this.page.mainContent.contentHeader.options.workspaceId).toBe(100);
            });
        });
    });
});
