describe("chorus.views.DatabaseColumnList", function() {
    describe("#render", function() {
        beforeEach(function() {
            this.dataset = backboneFixtures.workspaceDataset.datasetTable();
            this.dataset.setDatasetNumber(1);
            this.collection = backboneFixtures.databaseColumnSet([
                {
                    name: "column_name_1",
                    typeCategory: "BOOLEAN",
                    dataType: "boolean",
                    description: "column comment"
                },
                {
                    name: "column_name_2",
                    typeCategory: "WHOLE_NUMBER",
                    dataType: "int4",
                    description: "column comment"
                }
            ]);
            this.column1 = this.collection.at(0);
            this.column2 = this.collection.at(1);
            this.dataset.columns().reset(this.collection.models);
            this.view = new chorus.views.DatabaseColumnList({collection: this.collection});
            this.view.render();
        });

        it("defaults to selectMulti false", function() {
            expect(this.view.selectMulti).toBeFalsy();
        });

        it("renders an item for each column", function() {
            expect(this.view.$("> li").length).toBe(this.collection.length);
        });

        it("shows the comment for each column", function() {
            expect(this.view.$("li:eq(0) .summary")).toHaveText("column comment");
        });

        it("shows the type for each column", function() {
            expect(this.view.$("li:eq(0) .type")).toHaveClass("boolean");
            expect(this.view.$("li:eq(0) .type_name").text().trim()).toBe("boolean");

            expect(this.view.$("li:eq(1) .type")).toHaveClass("numeric");
            expect(this.view.$("li:eq(1) .type_name").text().trim()).toBe("int4");
        });

        it("sorts the columns by ordinalPosition", function() {
            expect(this.view.$("li:eq(0) .name")).toHaveText("column_name_1");
            expect(this.view.$("li:eq(1) .name")).toHaveText("column_name_2");
        });

        it("subscribes to column:select_all", function() {
            expect(this.view).toHaveSubscription("column:select_all", this.view.selectAll);
        });

        it("subscribes to column:select_none", function() {
            expect(this.view).toHaveSubscription("column:select_none", this.view.selectNone);
        });

        it("subscribes to column:removed", function() {
            expect(this.view).toHaveSubscription("column:removed", this.view.deselectColumn);
        });

        describe("column:deselected", function() {
            beforeEach(function() {
                this.view.selectMulti = true;

                chorus.PageEvents.trigger("column:deselected", this.collection.at(0));
            });

            it("deselects the column", function() {
                expect(this.view.$("li.selected").length).toBe(0);
            });
        });

        describe("clicking on a list item", function() {
            beforeEach(function() {
                spyOn(chorus.PageEvents, "trigger").andCallThrough();
            });

            context("with selectMulti false", function() {
                it("has the first row selected by default", function() {
                    expect(this.view.$("li:eq(0)")).toHaveClass("selected");
                });

                context("selecting a column", function() {
                    beforeEach(function() {
                        this.view.$("li:eq(1)").click();
                    });

                    it("moves the selected class", function() {
                        expect(this.view.$("li:eq(0)")).not.toHaveClass("selected");
                        expect(this.view.$("li:eq(1)")).toHaveClass("selected");
                    });

                    it("triggers the column:selected page event with the corresponding model as an argument", function() {
                        expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("column:selected", this.collection.at(1));
                    });

                    it("triggers the column:deselected page event with the corresponding model as an argument", function() {
                        expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("column:deselected", this.collection.at(0));
                    });

                    describe("#selectNone", function() {
                        beforeEach(function() {
                            this.view.selectNone();
                        });

                        it("should remove class selected from all list items and select the first item", function() {
                            expect(this.view.$("li.selected").length).toBe(1);
                            expect(this.view.$("li:eq(0)")).toHaveClass("selected");
                        });
                    });
                });
            });

            context("with selectMulti true", function() {
                beforeEach(function() {
                    this.view.selectMulti = true;
                    this.view.render();
                });

                it("has nothing selected by default", function() {
                    expect(this.view.$("li.selected")).not.toExist();
                });

                context("with a column selected", function() {
                    beforeEach(function() {
                        this.column2.selected = true;
                        this.view.render();
                    });

                    it("renders a selected column as selected", function() {
                        expect(this.view.$('.selected').length).toBe(1);
                    });
                });

                context("selecting multiple", function() {
                    beforeEach(function() {
                        this.view.$("li:eq(0)").click();
                        this.view.$("li:eq(1)").click();
                    });

                    it("selects both", function() {
                        expect(this.view.$("li:eq(0)")).toHaveClass("selected");
                        expect(this.view.$("li:eq(1)")).toHaveClass("selected");
                    });

                    it("triggers the column:selected page event with the corresponding model as an argument", function() {
                        expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("column:selected", this.collection.at(0));
                        expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("column:selected", this.collection.at(1));
                    });

                    describe("deselecting", function() {
                        beforeEach(function() {
                            this.view.$("li:eq(1)").click();
                        });

                        it("can deselect everything", function() {
                            expect(this.view.$("li:eq(0)")).toHaveClass("selected");
                            expect(this.view.$("li:eq(1)")).not.toHaveClass("selected");

                            this.view.$("li:eq(0)").click();
                            expect(this.view.$("li:eq(0)")).not.toHaveClass("selected");
                        });

                        it("triggers the column:deselected event with the corresponding model as an argument", function() {
                            expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("column:deselected", this.collection.at(1));
                        });
                    });
                });


            });
        });

        describe("showDatasetName", function() {
            context("when enabled", function() {
                beforeEach(function() {
                    this.view.showDatasetName = true;
                    this.view.render();
                });

                it("shows the dataset name", function() {
                    expect(this.view.$("li:eq(0) .aliased_name .letter")).toContainText(this.column1.dataset.aliasedName);
                });
            });

            context("when disabled", function() {
                beforeEach(function() {
                    this.view.showDatasetName = false;
                    this.view.render();
                });

                it("does not show the dataset name", function() {
                    expect(this.view.$("li:eq(0) .aliased_name")).not.toExist();
                });
            });
        });
    });
});
