describe("chorus.views.ExistingTableImportDataGrid", function() {
    beforeEach(function() {
        this.qtip = stubQtip();
        this.sourceColumns = [
            {name: "col1", type: "text", values: ["val1.1", "val2.1", "val3.1"]},
            {name: "col2", type: "text", values: ["val1.2", "val2.2", "val3.2"]},
            {name: "col3", type: "text", values: ["val1.3", "val2.3", "val3.3"]},
            {name: "col4", type: "text", values: ["val1.4", "val2.4", "val3.4"]},
            {name: "col5", type: "text", values: ["val1.5", "val2.5", "val3.5"]}
        ];

        this.destinationColumns = [
            {name: "col1", typeCategory: "WHOLE_NUMBER"},
            {name: "col2", typeCategory: "STRING"},
            {name: "col3", typeCategory: "WHOLE_NUMBER"},
            {name: "col4", typeCategory: "WHOLE_NUMBER"},
            {name: "col5", typeCategory: "WHOLE_NUMBER"},
            {name: "col6", typeCategory: "WHOLE_NUMBER"}
        ];

        this.columnSet = backboneFixtures.databaseColumnSet(this.destinationColumns);

        this.rows = [
            ["val1.1", "val1.2", "val1.3", "val1.4", "val1.5"],
            ["val2.1", "val2.2", "val2.3", "val2.4", "val2.5"],
            ["val3.1", "val3.2", "val3.3", "val3.4", "val3.5"]
        ];

        this.view = new chorus.views.ExistingTableImportDataGrid();
        $('#jasmine_content').append(this.view.el);
        this.view.setDestinationColumns(this.columnSet.models);
        this.view.render();
        this.view.initializeDataGrid(this.sourceColumns, this.rows);

        this.updatedSpy = jasmine.createSpy("updated");
        this.view.on("updatedDestinationCount", this.updatedSpy);
    });

    it('shows a mapping selector for each of the columns in the csv', function(){
        var $columnMaps = this.view.$(" .column_mapping");
        expect($columnMaps.length).toEqual(5);

        _.each($columnMaps, function(el) {
            expect($(el).text()).toContainTranslation("dataset.import.table.existing.map_to");
            expect($(el).find("a").text()).toContainTranslation("dataset.import.table.existing.select_one");
            expect($(el).find("a")).toHaveClass("selection_conflict");
        });
    });

    it("has the right data in each cell", function() {
        $("#jasmine_content").append("<div class='foo'></div>");
        //If you assign the dialog element directly to #jasmine_content, the later teardown will destroy jasmine content
        this.view.setElement($("#jasmine_content .foo"));
        var grid = this.view.grid;
        _.each(this.view.$(".column_name"), function(column, i) {
            var cells = _.map([0,1,2,4], function(j){
                return grid.getCellNode(j, i);
            });

            expect(cells.length).toEqual(3);
            _.each(cells, function(cell, j) {
                expect($(cell)).toContainText("val" + (j + 1) + "." + (i + 1));
            });
        });
    });
    describe("choosing the mapping for a column in the csv", function() {
        var menuLinks, menus;

        beforeEach(function() {
            menuLinks = this.view.$(".column_mapping a");
            menuLinks.click(); // just to initialize all qtips
            menus = this.qtip.find("ul");
        });

        it("shows the destination columns and their types", function() {
            var $destinationColumnNames = menus.eq(0).find("li");
            expect($destinationColumnNames.length).toBe(this.destinationColumns.length);

            _.each($destinationColumnNames, function(li, i) {
                var $li = $(li);
                var type = chorus.models.DatabaseColumn.humanTypeMap[this.destinationColumns[i].typeCategory];
                expect($li.find("a")).toContainText("col" + (i + 1));
                expect($li.find(".type")).toContainText(type);
            }, this);
        });

        context("selecting a destination column", function() {
            beforeEach(function() {
                menus.eq(0).find("li:eq(1) a").click();
            });

            function itSelectsDestinationColumn(sourceIndex, destinationIndex, destinationName, options) {
                it("shows the right destination column as selected", function() {
                    expect(menuLinks.eq(sourceIndex)).toHaveText(destinationName);

                    var menu = menus.eq(sourceIndex);
                    expect(menu.find(".check").not(".hidden").length).toBe(1);
                    expect(menu.find(".name.selected").length).toBe(1);
                    var selectedLi = menu.find("li[name=" + destinationName + "]");
                    expect(selectedLi.find(".check")).not.toHaveClass("hidden");
                    expect(selectedLi.find(".name")).toHaveClass("selected");
                });

                if (options && options.conflict) {
                    it("marks that source column as having a selection conflict", function() {
                        expect(menuLinks.eq(sourceIndex)).not.toHaveClass("selected");
                        expect(menuLinks.eq(sourceIndex)).toHaveClass("selection_conflict");
                    });
                } else {
                    it("marks that source column as having been mapped", function() {
                        expect(menuLinks.eq(sourceIndex)).toHaveClass("selected");
                        expect(menuLinks.eq(sourceIndex)).not.toHaveClass("selection_conflict");
                    });
                }
            }
            function itHasSelectedCounts(counts) {
                it("updates the counts in all of the menus", function() {
                    _.each(menus, function(menu) {
                        _.each($(menu).find(".count"), function(el, index) {
                            var count = counts[index];
                            if (count > 0) {
                                expect($(el).text()).toContainText("(" + count + ")");
                            }
                        });
                    });
                });
            }

            itSelectsDestinationColumn(0, 1, "col2");
            itHasSelectedCounts([0, 1, 0, 0, 0]);

            it("does not update the text of a different destination column link", function() {
                expect(menuLinks.eq(1)).toContainTranslation("dataset.import.table.existing.select_one");
                expect(menuLinks.eq(1)).not.toHaveClass("selected");
                expect(menuLinks.eq(1)).toHaveClass("selection_conflict");
            });

            it("updates the progress tracker", function() {
                expect(this.updatedSpy).toHaveBeenCalledWith({count: 1, total: 5, frequencies: jasmine.any(Array)});
            });

            context("choosing the same destination column again", function() {
                beforeEach(function() {
                    menus.eq(0).find("li:eq(1) a").click();
                });

                itSelectsDestinationColumn(0, 1, "col2");
                itHasSelectedCounts([0, 1, 0, 0, 0]);

                it("does not double-count the column", function() {
                    expect(menus.eq(0).find("li:eq(1) .count")).toContainText("(1)");
                    expect(this.updatedSpy).toHaveBeenCalledWith({count: 1, total: 5, frequencies: jasmine.any(Array)});
                });
            });

            context("when choosing a different destination column for the same source column", function() {
                beforeEach(function() {
                    menus.eq(0).find("li:eq(2) a").click();
                });

                itSelectsDestinationColumn(0, 2, "col3");
                itHasSelectedCounts([0, 0, 1, 0, 0]);
            });

            context("when mapping another source column to the same destination column", function() {
                beforeEach(function() {
                    menus.eq(1).find("li:eq(1) a").click();
                });

                itSelectsDestinationColumn(0, 1, "col2", { conflict: true });
                itSelectsDestinationColumn(1, 1, "col2", { conflict: true });
                itHasSelectedCounts([0, 2, 0, 0, 0]);
            });

            context("when all source columns but one are mapped", function() {
                beforeEach(function() {
                    for (var i = 0; i < 4; i++) {
                        menus.eq(i).find("li a").eq(i).click();
                    }
                });

                itHasSelectedCounts([1, 1, 1, 1, 0]);

                it("the last unselected column map is still displayed with red", function() {
                    expect(menuLinks.eq(0)).toHaveClass("selected");
                    expect(menuLinks.eq(1)).toHaveClass("selected");
                    expect(menuLinks.eq(2)).toHaveClass("selected");
                    expect(menuLinks.eq(3)).toHaveClass("selected");
                    expect(menuLinks.eq(4)).toHaveClass("selection_conflict");
                });
            });
        });
    });

    describe("automapping", function() {
        beforeEach(function() {
            this.view.automap();
        });

        it("selects destination columns in the dataset's DDL order", function() {
            var columnNameLinks = this.view.$(".column_mapping a");
            expect(columnNameLinks.eq(0)).toHaveText("col1");
            expect(columnNameLinks.eq(1)).toHaveText("col2");
            expect(columnNameLinks.eq(2)).toHaveText("col3");
            expect(columnNameLinks.eq(3)).toHaveText("col4");
            expect(columnNameLinks.eq(4)).toHaveText("col5");

            expect(columnNameLinks).not.toHaveClass("selection_conflict");
        });

        it("fires the correct progress event", function() {
            expect(this.updatedSpy).toHaveBeenCalledWith({count: 5, total: 5, frequencies: jasmine.any(Array)});
        });
    });
});