describe("chorus.dialogs.NewTableImportCSV", function() {
    beforeEach(function() {
        spyOn(chorus.views.NewTableImportDataGrid.prototype, "initializeDataGrid");
        chorus.page = {};
        chorus.page.workspace = backboneFixtures.workspace({
            sandboxInfo: {
                name: "mySchema",
                database: { name: "myDatabase", dataSource: { name: "myDataSource" } }
            }
        });
        this.sandbox = chorus.page.workspace.sandbox();
        this.csvOptions = {
            tableName: 'foo_quux_bar',
            hasHeader: true,
            contents: [
                "COL1,col2, \"col3 ,col 4,Col_5",
                "val1.1,val1.2,val1.3,val1.4,val1.5",
                "val2.1,val2.2,val2.3,val2.4,val2.5",
                "val3.1,val3.2,val3.3,val3.4,val3.5"
            ]
        };

        this.model = new (chorus.models.Base.extend({
            constructorName: 'FakeModel',
            urlTemplate: "workspaces/123/external_tables"
        }))();

        this.dialog = new chorus.dialogs.NewTableImportCSV({ model: this.model, csvOptions: this.csvOptions });
        this.dialog.render();
    });

    it("has the title", function() {
        expect(this.dialog.$('h1')).toContainTranslation("dataset.import.table.title");
    });

    it("has an import button", function() {
        expect(this.dialog.$('button.submit')).toContainTranslation("dataset.import.table.submit");
    });

    it("has comma as the default separator", function() {
        expect(this.dialog.$('input[name=delimiter]:checked').val()).toBe(',');
    });

    it("shows an error when the CSV doesn't parse correctly", function() {
        this.dialog.$("input.delimiter[value=' ']").click();
        expect(this.dialog.$(".errors")).not.toBeEmpty();
    });

    function hasRightSeparator(separator) {
        return function() {
            beforeEach(function() {
                this.csvOptions = { contents: [
                    "COL1" + separator + "col2" + separator + "col3" + separator + "col_4" + separator + "Col_5",
                    "val1.1" + separator + "val1.2" + separator + "val1.3" + separator + "val1.4" + separator + "val1.5",
                    "val2.1" + separator + "val2.2" + separator + "val2.3" + separator + "val2.4" + separator + "val2.5",
                    "val3.1" + separator + "val3.2" + separator + "val3.3" + separator + "val3.4" + separator + "val3.5"
                ],
                    tableName: 'foo_quux_bar'
                };

                this.dialog.teardown();
                //If you don't tear down the old dialog, spying on function calls becomes tricky later
                this.dialog = new chorus.dialogs.NewTableImportCSV({ model: this.model, csvOptions: this.csvOptions });
            });

            it("has " + separator + " as separator", function() {
                this.dialog.render();
                this.dialog.$("input.delimiter[value='" + separator + "']").click();
                expect(this.dialog.$('input.delimiter:checked').val()).toBe(separator);
            });

            it("reparses the file with " + separator + " as the separator", function() {
                this.dialog.render();
                this.dialog.importDataGrid.initializeDataGrid.reset();
                this.dialog.$("input.delimiter[value='" + separator + "']").click();
                var call = this.dialog.importDataGrid.initializeDataGrid.lastCall();
                expect(call.args[0].length).toEqual(5);
            });
        };
    }

    describe("click the 'tab' separator", hasRightSeparator('\t'));
    describe("click the 'comma' separator", hasRightSeparator(','));
    describe("click the 'semicolon' separator", hasRightSeparator(';'));
    describe("click the 'space' separator", hasRightSeparator(' '));

    describe("changing the separator", function() {
        beforeEach(function() {
            expect(this.dialog.model.get("types").length).toBe(5);
            this.dialog.$("input.delimiter[value=';']").click();
        });

        it("recalculates the column types", function() {
            expect(this.dialog.model.get("types").length).toBe(1);
        });

        it("recalculates the column names", function() {
            var expectedName = chorus.utilities.CsvParser.normalizeColumnName(this.csvOptions.contents[0]);
            expect(this.dialog.getColumnNames()).toEqual([expectedName]);
        });
    });

    describe("other delimiter input field", function() {
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
                    this.csvOptions = {contents: [
                        "COL1zcol2zcol3zcol_4zCol_5",
                        "val1.1zval1.2zval1.3zval1.4zval1.5",
                        "val2.1zval2.2zval2.3zval2.4zval2.5",
                        "val3.1zval3.2zval3.3zval3.4zval3.5"
                    ],
                        tableName: 'foo_quux_bar'
                    };

                    this.dialog.teardown();
                    this.dialog = new chorus.dialogs.NewTableImportCSV({ model: this.model, csvOptions: this.csvOptions });
                    this.dialog.render();

                    this.dialog.importDataGrid.initializeDataGrid.reset();
                    this.dialog.$("input#delimiter_other").click();

                    this.dialog.$('input[name=custom_delimiter]').val("z");
                    this.dialog.$('input[name=custom_delimiter]').trigger('keyup');
                });

                it("has z as separator", function() {
                    expect(this.dialog.$('input.delimiter:checked').val()).toBe('other');
                });

                it("creates a grid with the right number of z-delimited columns", function() {
                    var call = this.dialog.importDataGrid.initializeDataGrid.lastCall();
                    expect(call.args[0].length).toEqual(5);
                });
            });
        });
    });

    it("has directions", function() {
        expect(this.dialog.$('.directions')).toContainTranslation("dataset.import.table.new.directions", {
            tablename_input_field: ''
        });

        expect(this.dialog.$(".directions input:text").val()).toBe("foo_quux_bar");
    });

    context("when the 'includeHeader' property is not overridden", function() {
        it("has the include header row checkbox checked by default", function() {
            expect(this.dialog.$("#hasHeader")).toBeChecked();
        });
    });

    context("when the 'includeHeader' property is false", function() {
        it("has the header row checkbox unchecked and hidden", function() {
            var Subclass = chorus.dialogs.NewTableImportCSV.extend({ includeHeader: false });
            this.dialog = new Subclass({ model: this.model, csvOptions: this.csvOptions });
            this.dialog.render();

            var checkbox = this.dialog.$("#hasHeader");
            expect(checkbox).not.toExist();
        });
    });

    describe("the data grid", function() {
        it("converts the column names into db friendly format", function() {
            var call = this.dialog.importDataGrid.initializeDataGrid.lastCall();
            expect(_.pluck(call.args[0], "name")).toEqual([
                "col1", "col2", "col3", "col_4", "col_5"
            ]);
        });

        it("initializes the data grid with the correct rows", function() {
            var call = this.dialog.importDataGrid.initializeDataGrid.lastCall();
            expect(call.args[1]).toEqual([
                ["val1.1", "val1.2", "val1.3", "val1.4", "val1.5"],
                ["val2.1", "val2.2", "val2.3", "val2.4", "val2.5"],
                ["val3.1", "val3.2", "val3.3", "val3.4", "val3.5"]
            ]);
        });
    });

    describe("unchecking the include header box", function() {
        beforeEach(function() {
            spyOn(this.dialog, "postRender").andCallThrough();
            spyOn(this.dialog, "recalculateScrolling").andCallThrough();
            this.dialog.$("#hasHeader").prop("checked", false);
            this.dialog.$("#hasHeader").change();
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

        describe("and then rechecking the box", function() {
            beforeEach(function() {
                this.dialog.postRender.reset();
                this.dialog.$("#hasHeader").prop("checked", true).change();
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

            it("retains user-defined column names in the header", function() {
                var columnNames = ["one", "two", "gobbledigook", "four", "five"];
                spyOn(this.dialog.importDataGrid, "getColumnNames").andReturn(columnNames);

                this.dialog.$("#hasHeader").prop("checked", false).change();
                this.dialog.$("#hasHeader").prop("checked", true).change();

                var call = this.dialog.importDataGrid.initializeDataGrid.lastCall();
                expect(call.args[2]).toEqual(columnNames);
            });

            it("retains generated column names in the header", function() {
                this.dialog.$("#hasHeader").prop("checked", false).change();

                var columnNames = ["one", "two", "gobbledigook", "four", "five"];
                spyOn(this.dialog.importDataGrid, "getColumnNames").andReturn(columnNames);

                this.dialog.$("#hasHeader").prop("checked", true).change();
                this.dialog.$("#hasHeader").prop("checked", false).change();

                var call = this.dialog.importDataGrid.initializeDataGrid.lastCall();
                expect(call.args[2]).toEqual(columnNames);
            });

            it("retains the table name", function() {
                this.dialog.$("input[name=tableName]").val("testisgreat").change();
                this.dialog.$("#hasHeader").prop("checked", false).change();
                this.dialog.$("#hasHeader").prop("checked", true).change();
                expect(this.dialog.$("input[name=tableName]").val()).toBe("testisgreat");
            });
        });

        describe("after switching delimiter", function() {
            beforeEach(function() {
                this.dialog.$("input.delimiter[value=';']").click();
            });

            describe("and then rechecking the box", function() {
                beforeEach(function() {
                    this.dialog.postRender.reset();
                    this.dialog.$("#hasHeader").prop("checked", true).change();
                });

                it("has the correct header row", function() {
                    var columnNames = chorus.utilities.CsvParser.normalizeColumnName(this.csvOptions.contents[0]);
                    var call = this.dialog.importDataGrid.initializeDataGrid.lastCall();
                    expect(call.args[2]).toEqual([columnNames]);
                });
            });
        });
    });

    describe("with invalid column names", function() {
        beforeEach(function() {
            var columnNames = ["", "a ", "three", "four", "five"];
            spyOn(this.dialog.importDataGrid, "getColumnNames").andReturn(columnNames);
            spyOn(this.dialog.importDataGrid, "markColumnNameInputAsInvalid");
            this.dialog.$("button.submit").click();
        });

        it("does not put the button in the loading state", function() {
            expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
        });

        it("marks that inputs invalid", function() {
            expect(this.dialog.importDataGrid.markColumnNameInputAsInvalid).toHaveBeenCalledWith(0);
            expect(this.dialog.importDataGrid.markColumnNameInputAsInvalid).toHaveBeenCalledWith(1);
        });

        it("Displays a dialog error about the columns", function() {
            expect(this.dialog.$(".errors")).toContainTranslation("dataset.import.invalid_columns", {numInvalid: 2, numTotal: 5});
            expect(this.dialog.$(".errors")).not.toHaveClass("hidden");
        });

        describe("performValidation", function() {
            it("does not validate", function() {
                expect(this.dialog.performValidation()).toBe(false);
            });
        });

        describe("correcting part of the invalid data", function() {
            beforeEach(function() {
                this.dialog.importDataGrid.getColumnNames.andReturn(["", "a", "three", "four", "five"]);
                this.dialog.importDataGrid.markColumnNameInputAsInvalid.reset();
                this.dialog.$("button.submit").click();
            });

            it("removes the error warning from the corrected element", function() {
                expect(this.dialog.importDataGrid.markColumnNameInputAsInvalid).toHaveBeenCalledWith(0);
                expect(this.dialog.importDataGrid.markColumnNameInputAsInvalid).not.toHaveBeenCalledWith(1);
            });
        });
    });

    describe("with invalid table name", function() {
        beforeEach(function() {
            this.$tableNameInput = this.dialog.$(".directions input:text");
            this.$tableNameInput.attr('value', '');

            this.dialog.$("button.submit").click();
        });

        it("marks that inputs invalid", function() {
            expect(this.$tableNameInput).toHaveClass("has_error");
        });

        it("does not show anything in the dialog error bar", function () {
            expect(this.dialog.$(".errors")).toHaveClass("hidden");
        });

        describe("performValidation", function() {
            it("does not validate", function() {
                expect(this.dialog.performValidation()).toBe(false);
            });
        });
    });

    describe("clicking the import button", function() {
        beforeEach(function() {
            spyOn(this.dialog, "closeModal");
        });

        it("starts the spinner", function() {
            this.dialog.$("button.submit").click();

            expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
            expect(this.dialog.$("button.submit").text().trim()).toMatchTranslation("dataset.import.importing");
        });

        it("imports the file", function() {
            var columnNames = ["one", "two", "gobbledigook", "four", "five"];
            var columnTypes = ["text", "text", "text", "text", "text"];
            spyOn(this.dialog.importDataGrid, "getColumnNames").andReturn(columnNames);
            spyOn(this.dialog.importDataGrid, "getColumnTypes").andReturn(columnTypes);
            this.dialog.$("button.submit").click();

            expect(this.server.lastCreate().url).toBe(this.dialog.model.url());
            var json = this.server.lastCreate().json();

            expect(json["fake_model"]["types"]).toEqual(columnTypes);
            expect(json["fake_model"]["table_name"]).toBe("foo_quux_bar");
            expect(json["fake_model"]["delimiter"]).toBe(",");

            expect(json["fake_model"]["column_names"]).toEqual(columnNames);
        });

        context("when the post to import responds with success", function() {
            beforeEach(function() {
                this.dialog.$("button.submit").click();
                spyOn(chorus, 'toast');
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
        });

        context("when the import fails", function() {
            beforeEach(function() {
                this.dialog.$("button.submit").click();
                this.server.lastCreateFor(this.dialog.model).failUnprocessableEntity({ fields: { a: { BLANK: {} } } });
            });

            it("displays the error", function() {
                expect(this.dialog.$(".errors")).toContainText("A can't be blank");
            });

            it("re-enables the submit button", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
            });

            it("retains the table name", function() {
                this.dialog.$("input[name=tableName]").val("testisgreat").change();
                this.dialog.$("button.submit").click();
                this.server.lastCreate().failUnprocessableEntity({ fields: { a: { BLANK: {} } } });
                expect(this.dialog.$("input[name=tableName]").val()).toBe("testisgreat");
            });

            context("when the table name is already taken", function() {
                beforeEach(function() {
                    this.dialog.$("input[name=tableName]").val("testisgreat").change();
                    this.dialog.$("button.submit").click();
                    this.server.lastCreate().failUnprocessableEntity({ fields: { base: { TABLE_EXISTS: { table_name: "testisgreat", suggested_table_name: "testisgreat_1" }}}});
                });

                it("saves new name in the model attributes", function() {
                    this.dialog.$("input[name=tableName]").val("the_wizard_of_oz").change();
                    this.dialog.$("button.submit").click();
                    expect(this.dialog.model.get("toTable")).toBe("the_wizard_of_oz");
                    expect(this.dialog.model.get("tableName")).toBe("the_wizard_of_oz");
                });
            });
        });
    });
});
