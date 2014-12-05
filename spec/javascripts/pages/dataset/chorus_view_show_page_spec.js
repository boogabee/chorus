describe("chorus.pages.ChorusViewShowPage", function() {
    beforeEach(function() {
        chorus.page = {workspace: this.workspace};

        this.chorusView = backboneFixtures.workspaceDataset.chorusView();
        this.workspace = this.chorusView.workspace();

        this.columnSet = this.chorusView.columns();

        this.datasetId = this.chorusView.get('id');

        spyOn(chorus.pages.ChorusViewShowPage.prototype, "drawColumns").andCallThrough();
        this.page = new chorus.pages.ChorusViewShowPage(this.workspace.get("id"), this.datasetId);
    });

    describe("#initialize", function() {
        context("when the workspace fetch completes", function() {
            beforeEach(function() {
                this.server.completeFetchFor(this.workspace);
            });

            it("constructs a ChorusView with the right id", function() {
                expect(this.page.model).toBeA(chorus.models.ChorusView);
                expect(this.page.model.get("id")).toBe(this.datasetId);
            });

            context("when the Chorus View fetch completes", function() {
                beforeEach(function() {
                    spyOn(chorus.router, "navigate");
                    this.server.completeFetchFor(this.chorusView);
                });

                it("does not navigate again", function() {
                    expect(chorus.router.navigate).not.toHaveBeenCalled();
                });

                describe("when the columnSet fetch completes", function() {
                    beforeEach(function() {
                        this.server.completeFetchAllFor(this.columnSet, backboneFixtures.databaseColumnSet());
                    });

                    describe("when editing a chorus view", function() {
                        beforeEach(function() {
                            this.oldHeader = this.page.mainContent.contentHeader;
                            spyOn(this.page, 'render');
                            this.page.mainContent.contentDetails.trigger("dataset:edit");
                        });

                        it("sets the main content to DatasetEditChorusView", function() {
                            expect(this.page.mainContent.content).toBeA(chorus.views.DatasetEditChorusView);
                        });

                        it("keeps the header", function() {
                            expect(this.page.mainContent.contentHeader).toBe(this.oldHeader);
                        });

                        it("should not re-render", function() {
                            expect(this.page.render).not.toHaveBeenCalled();
                        });

                        describe("when user cancel edit dataset and dataset:cancelEdit is triggered", function() {
                            beforeEach(function() {
                                this.page.drawColumns.reset();
                                chorus.PageEvents.trigger("dataset:cancelEdit");
                            });

                            it("re-draws the page", function() {
                                expect(this.page.drawColumns).toHaveBeenCalled();
                            });
                        });
                    });
                });
            });
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.server.completeFetchFor(this.workspace);
            this.resizedSpy = spyOnEvent(this.page, 'resized');
            this.server.completeFetchFor(this.chorusView);
            this.server.completeFetchAllFor(this.columnSet, [backboneFixtures.databaseColumn(), backboneFixtures.databaseColumn()]);
            this.server.completeFetchFor(this.chorusView.statistics());
        });

        describe("when the transform:sidebar event is triggered", function() {
            beforeEach(function() {
                this.page.render();
                spyOn(this.page, 'render');
            });

            context("for a chorus view", function() {
                beforeEach(function() {
                    this.page.secondarySidebar = new chorus.views.Base();
                    this.originalSidebar = this.page.secondarySidebar;
                    spyOn(this.originalSidebar, "teardown");
                    spyOn(this.page.mainContent.content, 'render').andCallThrough();
                    this.page.mainContent.contentDetails.trigger("transform:sidebar", 'chorus_view');
                });

                it("tears the old sidebar down", function() {
                    expect(this.originalSidebar.teardown).toHaveBeenCalled();
                });

                it("disables the sidebar", function() {
                    expect(this.page.sidebar.disabled).toBeTruthy();
                });

                it("sets the datasetNumber to 1", function() {
                    expect(this.page.dataset.datasetNumber).toBe(1);
                });

                it("enables multi-select on the main content", function() {
                    expect(this.page.mainContent.content.selectMulti).toBeTruthy();
                });

                it("enables showDatasetName on the main content", function() {
                    expect(this.page.mainContent.content.showDatasetName).toBeTruthy();
                    expect(this.page.mainContent.content.render).toHaveBeenCalled();
                });

                it("should swap out the sidebar for the chorus view sidebar", function() {
                    expect(this.page.secondarySidebar).toBeA(chorus.views.CreateChorusViewSidebar);
                });

                it("removes the current selection from the column list", function() {
                    expect(this.page.mainContent.content.$("li.selected").length).toBe(0);
                });

                it("passes down the columnSet to the sidebar", function() {
                    expect(this.page.secondarySidebar.options.aggregateColumnSet).toBe(this.page.columnSet);
                });

                describe("after cancelling", function() {
                    beforeEach(function() {
                        this.page.mainContent.content.render.reset();
                        this.page.mainContent.content.selectAll();
                        var otherColumn = backboneFixtures.databaseColumn();
                        otherColumn.dataset = this.page.model;
                        this.page.columnSet.add(otherColumn);
                        chorus.PageEvents.trigger('cancel:sidebar', 'chorus_view');
                    });

                    it("tears the old sidebar down", function() {
                        expect(this.originalSidebar.teardown).toHaveBeenCalled();
                    });

                    it("enables the sidebar", function() {
                        expect(this.page.sidebar.disabled).toBeFalsy();
                    });

                    it("clears the datasetNumber", function() {
                        expect(this.page.dataset.datasetNumber).toBeUndefined();
                    });

                    it("restores the columnSet to the base set of columns from the dataset", function() {
                        expect(this.page.columnSet.models).toEqual(this.page.dataset.columns().models);
                    });

                    it("disables multi-select on the main content", function() {
                        expect(this.page.mainContent.content.selectMulti).toBeFalsy();
                    });

                    it("disables showDatasetName on the main content", function() {
                        expect(this.page.mainContent.content.showDatasetName).toBeFalsy();
                        expect(this.page.mainContent.content.render).toHaveBeenCalled();
                    });

                    it("selects only the first item", function() {
                        expect(this.page.mainContent.content.$("li").length).toBe(2);
                        expect(this.page.mainContent.content.$("li:eq(0)")).toHaveClass("selected");
                        expect(this.page.mainContent.content.$("li:eq(1)")).not.toHaveClass("selected");
                    });
                });

                describe("clicking select all", function() {
                    beforeEach(function() {
                        this.selectSpy = jasmine.createSpy("column selected spy");
                        chorus.PageEvents.on("column:selected", this.selectSpy);
                        this.page.mainContent.contentDetails.$("a.select_all").click();
                    });

                    it("adds the selected class to each column li", function() {
                        expect(this.page.mainContent.content.$("li.selected").length).toBe(this.page.mainContent.content.$("li").length);
                    });

                    it("triggers the column:selected page event once for each li", function() {
                        expect(this.selectSpy.calls.count()).toBe(this.page.mainContent.content.$("li.selected").length);
                    });

                    describe("clicking select none", function() {
                        beforeEach(function() {
                            this.deselectSpy = jasmine.createSpy("column deselected spy");
                            chorus.PageEvents.on("column:deselected", this.deselectSpy);
                            this.page.mainContent.contentDetails.$("a.select_none").click();
                        });

                        it("removes the selected class from each column li", function() {
                            expect(this.page.mainContent.content.$("li.selected").length).toBe(0);
                        });

                        it("triggers column:deselected once for each li", function() {
                            expect(this.deselectSpy.calls.count()).toBe(this.page.mainContent.content.$("li").length);
                        });
                    });
                });
            });

            context("for an edit chorus view", function() {
                beforeEach(function() {
                    this.page.mainContent.contentDetails.trigger("transform:sidebar", 'edit_chorus_view');
                });

                it("swaps out the sidebar for the dataset edit chorus view sidebar", function() {
                    expect(this.page.secondarySidebar).toBeA(chorus.views.DatasetEditChorusViewSidebar);
                });
            });

            describe("when the cancel:sidebar event is triggered", function() {
                beforeEach(function() {
                    this.page.mainContent.contentDetails.trigger("transform:sidebar", "edit_chorus_view");
                    expect(this.page.$('#sidebar .sidebar_content.secondary')).toHaveClass("dataset_edit_chorus_view_sidebar");
                    this.resizedSpy.reset();

                    chorus.PageEvents.trigger('cancel:sidebar', 'edit_chorus_view');
                });

                it("triggers 'resized' on the page", function() {
                    expect('resized').toHaveBeenTriggeredOn(this.page);
                });

                it("restores the original sidebar while hiding the secondarySidebar", function() {
                    expect(this.page.$('#sidebar .sidebar_content.primary')).not.toHaveClass('hidden');
                    expect(this.page.$('#sidebar .sidebar_content.secondary')).toHaveClass('hidden');
                });

                it("removes all classes added when transform:sidebar is triggered", function() {
                    expect(this.page.$('#sidebar .sidebar_content.secondary')).not.toHaveClass("chart_configuration");
                });
            });
        });
    });
});
