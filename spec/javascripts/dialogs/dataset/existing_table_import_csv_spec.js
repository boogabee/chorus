describe("chorus.dialogs.ExistingTableImportCSV", function() {
    beforeEach(function() {
        spyOn(chorus.views.ExistingTableImportDataGrid.prototype, 'initializeDataGrid');
        spyOn(chorus.views.ExistingTableImportDataGrid.prototype, 'automap');

        chorus.page = {};
        chorus.page.workspace = backboneFixtures.workspace({
            sandboxInfo: {
                name: "mySchema",
                database: { name: "myDatabase", dataSource: { name: "myDataSource" } }
            }
        });
        this.sandbox = chorus.page.workspace.sandbox();
        this.csvOptions = {
            tableName: 'existing_table',
            hasHeader: true,
            contents: [
                "COL1,col2, col3 ,col 4,Col_5",
                "val1.1,val1.2,val1.3,val1.4,val1.5",
                "val2.1,val2.2,val2.3,val2.4,val2.5",
                "val3.1,val3.2,val3.3,val3.4,val3.5",
                "val4.1,val4.2,val4.3,val4.4,val4.5"
            ]
        };

        this.model = new (chorus.models.Base.extend({
            constructorName: 'FakeModel',
            urlTemplate: "workspaces/{{workspaceId}}/existing_tables"
        }))();

        this.model.set({
            truncate: true,
            workspaceId: '123'
        }, { silent: true });

        this.dialog = new chorus.dialogs.ExistingTableImportCSV({model: this.model, csvOptions: this.csvOptions , datasetId: "dat-id"});

        this.columns = [
            {name: "col1", typeCategory: "WHOLE_NUMBER", ordinalPosition: "3"},
            {name: "col2", typeCategory: "STRING", ordinalPosition: "4"},
            {name: "col3", typeCategory: "WHOLE_NUMBER", ordinalPosition: "1"},
            {name: "col4", typeCategory: "WHOLE_NUMBER", ordinalPosition: "2"},
            {name: "col5", typeCategory: "WHOLE_NUMBER", ordinalPosition: "5"},
            {name: "col6", typeCategory: "WHOLE_NUMBER", ordinalPosition: "6"}
        ];
        this.dataset = backboneFixtures.workspaceDataset.datasetTable({
            id: "dat-id",
            workspace: {id: this.model.get("workspaceId")}
        });
        this.server.completeFetchFor(this.dataset);
        this.qtip = stubQtip();
        spyOn(this.dialog.dataGrid, "setDestinationColumns").andCallThrough();
        this.server.completeFetchFor(this.dialog.columnSet, this.columns);
    });

    it("has the title", function() {
        expect(this.dialog.$('h1')).toContainTranslation("dataset.import.table.title");
    });

    it("has an import button", function() {
        expect(this.dialog.$('button.submit')).toContainTranslation("dataset.import.table.submit");
    });

    it("has the import button disabled by default", function() {
        expect(this.dialog.$('button.submit')).toBeDisabled();
    });

    it("has comma as the default separator", function() {
        expect(this.dialog.$('input[name=delimiter]:checked').val()).toBe(',');
    });

    it("shows an error when the CSV doesn't parse correctly", function() {
        this.csvOptions.contents.push('"Has Spaces",2,3,4,5');
        this.dialog.$("input.delimiter[value=' ']").click();

        expect(this.model.serverErrors).toBeDefined();
        expect(this.dialog.$(".errors")).not.toBeEmpty();
    });

    it("has instructions", function() {
        expect(this.dialog.$('.directions')).toContainTranslation("dataset.import.table.existing.directions",
            {
                toTable: "existing_table"
            });
    });

    it("has a progress tracker", function() {
        this.dialog.dataGrid.trigger("updatedDestinationCount", {count: 0, total: 5, frequencies: [0,0,0,0,0]});
        expect(this.dialog.$(".progress")).toContainTranslation("dataset.import.table.progress", {count: 0, total: 5});
    });

    it("has an auto-map link", function() {
        expect(this.dialog.$("a.automap")).toContainTranslation("dataset.import.table.automap");
    });

    it("checks the include header row checkbox by default", function() {
        expect(this.dialog.$("#hasHeader")).toBeChecked();
    });

    describe("when validation fails", function() {
        beforeEach(function() {
            this.model.trigger("validationFailed");
        });

        it("disables the submit button", function() {
            expect(this.dialog.$("button.submit")).toBeDisabled();
        });
    });

    describe("separators", function() {
        function hasRightSeparator(separator) {
            return function() {
                beforeEach(function() {
                    this.csvOptions = {
                        contents: [
                            "COL1" + separator + "col2" + separator + "col3" + separator + "col_4" + separator + "Col_5",
                            "val1.1" + separator + "val1.2" + separator + "val1.3" + separator + "val1.4" + separator + "val1.5",
                            "val2.1" + separator + "val2.2" + separator + "val2.3" + separator + "val2.4" + separator + "val2.5",
                            "val3.1" + separator + "val3.2" + separator + "val3.3" + separator + "val3.4" + separator + "val3.5"
                        ],
                        tableName: 'existing_table'
                    };

                    this.dialog.teardown();
                    //If you don't tear down the old dialog, spying on function calls becomes tricky later
                    this.dialog = new chorus.dialogs.ExistingTableImportCSV({model: this.model, csvOptions: this.csvOptions, datasetId: "dat-id"});
                    this.server.completeFetchFor(this.dataset);
                    this.dialog.render();

                    this.dialog.$("input.delimiter[value='" + separator + "']").click();

                });

                it("has " + separator + " as separator", function() {
                    expect(this.dialog.$('input.delimiter:checked').val()).toBe(separator);
                });

                it("reparses the file with " + separator + " as the separator", function() {
                    this.dialog.render();
                    this.dialog.dataGrid.initializeDataGrid.reset();
                    this.dialog.$("input.delimiter[value='" + separator + "']").click();
                    var call = this.dialog.dataGrid.initializeDataGrid.lastCall();
                    expect(call.args[0].length).toEqual(5);
                });
            };
        }
        describe("selecting the 'tab' separator", hasRightSeparator('\t'));
        describe("selecting the 'comma' separator", hasRightSeparator(','));
        describe("selecting the 'semicolon' separator", hasRightSeparator(';'));
        describe("selecting the 'space' separator", hasRightSeparator(' '));
    });

    describe("changing the separator", function() {
        beforeEach(function() {
            expect(this.dialog.model.get("types").length).toBe(5);
            this.dialog.$("input.delimiter[value=';']").click();
        });

        it("recalculates the column types", function() {
            expect(this.dialog.model.get("types").length).toBe(1);
        });
    });

    describe("specifying a custom delimiter", function() {
        beforeEach(function() {
            this.otherField = this.dialog.$('input[name=custom_delimiter]');
        });

        it("is empty on loading", function() {
            expect(this.otherField.val()).toBe("");
        });

        it("checks the Other radio button", function() {
            this.otherField.val("X");
            this.otherField.trigger("keyup");
            expect(this.dialog.$('input.delimiter[type=radio]:checked').val()).toBe("other");
        });

        it("retains its value after re-render", function() {
            this.otherField.val("X");
            this.otherField.trigger("keyup");
            expect(this.otherField).toHaveValue("X");
        });

        describe("clicking on radio button Other", function() {
            beforeEach(function() {
                spyOn($.fn, 'focus');
                this.dialog.$("input#delimiter_other").click();
            });

            it("focuses the text field", function() {
                expect($.fn.focus).toHaveBeenCalled();
                expect($.fn.focus.lastCall().object).toBe("input:text");
            });

            describe("entering 'z' as a separator", function() {
                beforeEach(function() {
                    this.csvOptions =  {
                        contents: [
                            "COL1zcol2zcol3zcol_4zCol_5",
                            "val1.1zval1.2zval1.3zval1.4zval1.5",
                            "val2.1zval2.2zval2.3zval2.4zval2.5",
                            "val3.1zval3.2zval3.3zval3.4zval3.5"
                        ],
                        tableName: "existing_table"
                    };


                    this.dialog = new chorus.dialogs.ExistingTableImportCSV({model: this.model, csvOptions: this.csvOptions, datasetId: "dat-id"});
                    this.server.completeFetchFor(this.dataset);
                    this.dialog.render();

                    this.dialog.$("input#delimiter_other").click();
                    this.dialog.$('input[name=custom_delimiter]').val("z");
                    this.dialog.$('input[name=custom_delimiter]').trigger('keyup');
                });

                it("has z as separator", function() {
                    expect(this.dialog.$('input.delimiter:checked').val()).toBe('other');
                });

                it("reparses the file with z as the separator", function() {
                    var call = this.dialog.dataGrid.initializeDataGrid.lastCall();
                    expect(call.args[0].length).toEqual(5);
                });
            });
        });
    });

    describe("clicking the 'automap' link", function() {
        beforeEach(function() {
            this.dialog.$("a.automap").click();
        });

        it("displays the correct progress text", function() {
            expect(this.dialog.dataGrid.automap).toHaveBeenCalled();
        });
    });

    describe("the data grid subview", function() {
        it("is initialized with destination columns", function(){
            expect(this.dialog.dataGrid.setDestinationColumns).toHaveBeenCalledWith(this.dialog.columnSet.models);
        });

        it("is initialized with source columns and rows", function(){
            var call = this.dialog.dataGrid.initializeDataGrid.lastCall();
            var expectedColumnNames = ['col1', 'col2', 'col3', 'col_4', 'col_5'];
            var expectedRows = ['val1.1', 'val1.2', 'val1.3', 'val1.4', 'val1.5'];
            expect(_.pluck(call.args[0], "name")).toEqual(expectedColumnNames);
            expect(call.args[1][0]).toEqual(expectedRows);
        });

        it("updates the column count when destination count changes", function() {
            this.dialog.dataGrid.trigger("updatedDestinationCount", {count: 23, total: 81});
            expect(this.dialog.$(".progress")).toContainTranslation("dataset.import.table.progress", { count: 23, total: 81 });
        });
    });

    describe("unchecking the include header box", function() {
        beforeEach(function() {
            spyOn(this.dialog, "postRender").andCallThrough();
            spyOn(this.dialog, "recalculateScrolling").andCallThrough();
            this.dialog.$("#hasHeader").prop("checked", false).change();
        });

        it("sets header on the csv model", function() {
            expect(this.dialog.model.get("hasHeader")).toBeFalsy();
        });

        it("re-renders", function() {
            expect(this.dialog.postRender).toHaveBeenCalled();
        });

        it("the box is unchecked", function() {
            expect(this.dialog.$("#hasHeader").prop("checked")).toBeFalsy();
        });

        describe("rechecking the box", function() {
            beforeEach(function() {
                this.dialog.postRender.reset();
                this.dialog.$("#hasHeader").prop("checked", true);
                this.dialog.$("#hasHeader").change();
            });
            it("sets header on the csv model", function() {
                expect(this.dialog.model.get("hasHeader")).toBeTruthy();
            });
            it("re-renders", function() {
                expect(this.dialog.postRender).toHaveBeenCalled();
            });
            it("the box is checked", function() {
                expect(this.dialog.$("#hasHeader").prop("checked")).toBeTruthy();
            });
        });
    });

    context("when all columns have been mapped", function() {
        beforeEach(function() {
            spyOn(this.dialog, "closeModal");
            this.dialog.dataGrid.trigger("updatedDestinationCount", {count: 5, total: 5, frequencies: [1,1,1,1,1]});
        });

        it("enables the import button", function() {
            expect(this.dialog.$('button.submit')).toBeEnabled();
        });

        describe("with an existing toTable that has a funny name", function() {
            beforeEach(function() {
                this.dialog.tableName = "!@#$%^&*()_+";
                this.dialog.$("a.automap").click();
                this.server.reset();
                this.dialog.$("button.submit").click();
            });

            it("still imports and passes client side validation", function() {
                expect(this.server.lastCreateFor(this.dialog.model).url.length).toBeGreaterThan(0);
            });
        });

        context("clicking import button with invalid fields", function() {
            beforeEach(function() {
                spyOn(this.dialog.model, "performValidation").andReturn(false);
                this.dialog.$("button.submit").click();
            });

            it("re-enables the submit button", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
                expect(this.dialog.$("button.submit").text().trim()).toMatchTranslation("dataset.import.table.submit");
            });
        });

        describe("clicking the import button", function() {
            beforeEach(function() {
                this.dialog.dataGrid.columnMapping = this.expectedColumnNames;
                this.dialog.$("button.submit").click();
            });

            it("starts the spinner", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
                expect(this.dialog.$("button.submit").text().trim()).toMatchTranslation("dataset.import.importing");
            });

            it("imports the file", function() {
                expect(this.server.lastCreate().url).toBe(this.dialog.model.url());
                var json = this.server.lastCreate().json()["fake_model"];
                expect(json["file_name"]).toBe(this.dialog.model.get("fileName"));
                expect(json["table_name"]).toBe("existing_table");
                expect(json["delimiter"]).toBe(",");
                expect(json["type"]).toBe("existingTable");
                expect(json["has_header"]).toBe(true);
                expect(json["truncate"]).toBe(true);
                expect(json["column_names"]).toEqual(this.expectedColumnNames);
            });

            context("when the post to import responds with success", function() {
                beforeEach(function() {
                    spyOn(chorus, 'toast');
                    spyOn(chorus.router, "navigate");
                    spyOn(chorus.PageEvents, 'trigger');
                    this.server.lastCreateFor(this.dialog.model).succeed();
                });

                it("closes the dialog and displays a toast", function() {
                    expect(this.dialog.closeModal).toHaveBeenCalled();
                    expect(chorus.toast).toHaveBeenCalledWith("dataset.import.started");
                });

                it("triggers csv_import:started", function() {
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("csv_import:started");
                });

                it("should navigate to the destination sandbox table", function() {
                    expect(chorus.router.navigate).toHaveBeenCalledWith(this.dialog.dataset.showUrl());
                });
            });

            context("when the import fails", function() {
                beforeEach(function() {
                    this.server.lastCreateFor(this.dialog.model).failUnprocessableEntity({ fields: { a: { BLANK: {} } } });
                });

                it("displays the error", function() {
                    expect(this.dialog.$(".errors")).toContainText("A can't be blank");
                });

                it("re-enables the submit button", function() {
                    expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
                });
            });
        });

        describe("and then double mapping a destination column", function() {
            beforeEach(function() {
                this.dialog.dataGrid.trigger("updatedDestinationCount", {count: 5, total: 5, frequencies: [1,2,0,1,1]});
            });
            it("disables the import button", function() {
                expect(this.dialog.$('button.submit')).toBeDisabled();
            });
        });
    });

    describe("more source columns than destination columns", function() {
        context("when there are no destination columns", function() {
            beforeEach(function() {
                this.csvOptions = {
                    contents: ["a,b,c,d"],
                    tableName: 'existing_table'
                };

                this.dialog = new chorus.dialogs.ExistingTableImportCSV({model: this.model, csvOptions: this.csvOptions, datasetId: "dat-id"});
                this.server.completeFetchFor(this.dialog.dataset);
                this.server.completeFetchFor(this.dialog.columnSet);
            });

            it("displays the error message", function() {
                expect(this.dialog.$(".errors").text()).toContainTranslation("field_error.source_columns.LESS_THAN_OR_EQUAL_TO");
            });
        });

        context("when there are fewer destination columns", function() {
            beforeEach(function() {
                this.csvOptions = {
                    contents: [ "e,f,g" ],
                    tableName: 'existing_table'
                };

                this.dialog = new chorus.dialogs.ExistingTableImportCSV({model: this.model, csvOptions: this.csvOptions, datasetId: "dat-id"});
                this.server.completeFetchFor(this.dialog.dataset);
                this.columns = [
                    {name: "a", typeCategory: "WHOLE_NUMBER"}
                ];
                this.server.completeFetchFor(this.dialog.columnSet, this.columns);
            });

            it("displays error message", function() {
                expect(this.dialog.$(".errors").text()).toContainTranslation("field_error.source_columns.LESS_THAN_OR_EQUAL_TO");
            });

            context("and then selecting a column", function() {
                beforeEach(function() {
                    this.dialog.$(".column_mapping:eq(1)").click();
                    this.qtip.find(".qtip:eq(0) .ui-tooltip-content li:eq(1) a").click();
                });

                it("still shows the errors", function() {
                    expect(this.dialog.$(".errors").text()).toContainTranslation("field_error.source_columns.LESS_THAN_OR_EQUAL_TO");
                });
            });

            context("and then changing the delimiter", function() {
                beforeEach(function() {
                    this.dialog.$("input.delimiter[value=';']").click();
                });

                it("should clear the error message", function() {
                    expect(this.dialog.$(".errors").text()).toBe("");
                });
            });
        });
    });
});
