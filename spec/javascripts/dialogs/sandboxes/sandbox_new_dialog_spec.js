describe("chorus.dialogs.SandboxNew", function() {
    beforeEach(function() {
        this.workspace = backboneFixtures.workspace({id: 45});
        spyOn(chorus, "toast");
        spyOn(chorus, 'styleSelect');
        spyOn(chorus.router, 'reload');
        this.dialog = new chorus.dialogs.SandboxNew({ pageModel: this.workspace});
        this.server.completeFetchFor(this.workspace);
        this.dialog.render();
    });

    it("fetches the workspace", function() {
        expect(this.dialog.workspace).toHaveBeenFetched();
    });

    it("shows the checkbox for displaying sandbox datasets by default", function(){
        expect(this.dialog.$el).toContainTranslation("actions.sandbox.show_sandbox_datasets_by_default");
        expect(this.dialog.$("input[type='checkbox']")).toBeChecked();
    });

    context("when the SchemaPicker triggers an error", function() {
        beforeEach(function() {
            var modelWithError = backboneFixtures.schemaSet();
            modelWithError.serverErrors = { fields: { a: { BLANK: {} } } };
            this.dialog.schemaPicker.trigger("error", modelWithError);
        });

        it("shows the error", function() {
            expect(this.dialog.$('.errors')).toContainText("A can't be blank");
        });

        context("and then the schemaPicker triggers clearErrors", function() {
            it("clears the errors", function() {
                this.dialog.schemaPicker.trigger("clearErrors");
                expect(this.dialog.$('.errors')).toBeEmpty();
            });
        });
    });

    context("clicking the submit button", function() {
        beforeEach(function() {
            this.sandbox = this.dialog.model;
            spyOn(this.sandbox, 'save').andCallThrough();
        });

        context("without schema selected yet", function() {
            beforeEach(function() {
                spyOn(this.dialog.schemaPicker, 'fieldValues').andReturn({
                    dataSource: "4",
                    database: "5",
                    schemaName: ""
                });
                this.dialog.schemaPicker.trigger("change", "");
            });

            it("disables the submit button", function() {
                expect(this.dialog.$(".form_controls button.submit")).toBeDisabled();
            });
        });

        context('with a data source id, database id, and schema id', function() {
            beforeEach(function() {
                spyOn(this.dialog, 'closeModal');
                spyOn(this.dialog.schemaPicker, 'schemaId').andReturn("6");
                spyOn(this.dialog.schemaPicker, 'fieldValues').andReturn({
                    dataSource: "4",
                    database: "5",
                    schema: "6"
                });

                this.dialog.schemaPicker.trigger("change", "6");
                this.dialog.$("button.submit").click();
            });

            it("creates the sandbox", function() {
                expect(this.server.lastCreate().url).toBe('/workspaces/45/sandbox');
                var json = this.server.lastCreate().json()['sandbox'];
                expect(json['schema_id']).toBe('6');
                expect(json['database_id']).toBe('5');
                expect(json['data_source_id']).toBe('4');
            });

            it("doesn't yet display a toast", function() {
                expect(chorus.toast).not.toHaveBeenCalled();
            });

            it("changes the button text to 'Adding...'", function() {
                expect(this.dialog.$(".form_controls button.submit").text()).toMatchTranslation("sandbox.adding_sandbox");
            });

            it("sets the button to a loading state", function() {
                expect(this.dialog.$(".form_controls button.submit").isLoading()).toBeTruthy();
            });

            it("saves the workspace with the new sandbox id", function() {
                expect(this.server.lastCreate().url).toBe("/workspaces/45/sandbox");
                expect(this.server.lastCreate().json()["sandbox"]["schema_id"]).toBe('6');
            });

            describe("when save fails", function() {
                beforeEach(function() {
                    this.server.lastCreateFor(this.dialog.model).failUnprocessableEntity({ fields: { a: { BLANK: {} } } });
                });

                it("takes the button out of the loading state", function() {
                    expect(this.dialog.$(".form_controls button.submit").isLoading()).toBeFalsy();
                });

                it("displays the error message", function() {
                    expect(this.dialog.$(".errors")).toContainText("A can't be blank");
                });
            });

            describe("when the model is saved successfully", function() {
                beforeEach(function() {
                    spyOnEvent(this.dialog.workspace, 'invalidated');
                    spyOn(this.dialog.workspace, 'fetch');
                    this.dialog.model.trigger("saved");
                });

                context("when the 'noReload' option is set", function() {
                    it("does not reload the page", function() {
                        chorus.router.reload.reset();
                        this.dialog.options.noReload = true;
                        this.sandbox.trigger("saved");
                        expect(chorus.router.reload).not.toHaveBeenCalled();
                    });
                });

                it("shows a toast message", function() {
                    expect(chorus.toast).toHaveBeenCalledWith("sandbox.create.toast");
                });
            });

        });

        context('with a data source id, database id, and schema name', function() {
            beforeEach(function() {
                spyOn(this.dialog.schemaPicker, 'fieldValues').andReturn({
                    dataSource: "4",
                    database: "5",
                    schemaName: "new_schema"
                });

                this.dialog.schemaPicker.trigger("change", "new_schema");
                this.dialog.$("button.submit").click();
            });

            it("sets schema name on the sandbox", function() {
                expect(this.dialog.model.get("schemaName")).toBe("new_schema");
            });

            it("saves the workspace with the new sandbox name", function() {
                expect(this.server.lastCreate().url).toBe('/workspaces/45/sandbox');
                var json = this.server.lastCreate().json()['sandbox'];
                expect(json['schema_name']).toBe('new_schema');
                expect(json['schema_id']).toBeUndefined();
                expect(json['database_id']).toBe('5');
                expect(json['data_source_id']).toBe('4');
            });
        });

        context('with a data source id, database name and schema name, with sandbox datasets shown ', function() {
            beforeEach(function() {
                spyOn(this.dialog.schemaPicker, 'fieldValues').andReturn({
                    dataSource: "4",
                    databaseName: "new_database",
                    schemaName: "new_schema"
                });

                this.dialog.schemaPicker.trigger("change", "new_schema");
                this.dialog.$("button.submit").click();
            });

            it("sets the database name and schema name on the schema", function() {
                expect(this.dialog.model.get("databaseName")).toBe("new_database");
                expect(this.dialog.model.get("schemaName")).toBe("new_schema");
                expect(this.dialog.model.get("dataSourceId")).toBe("4");
            });

            it("saves the workspace with the new database and sandbox names", function() {
                expect(this.server.lastCreate().url).toBe('/workspaces/45/sandbox');
                var json = this.server.lastCreate().json()['sandbox'];
                expect(json['schema_name']).toBe('new_schema');
                expect(json['schema_id']).toBeUndefined();
                expect(json['database_name']).toBe('new_database');
                expect(json['data_source_id']).toBe('4');
                expect(json['show_sandbox_datasets']).toBe(true);
            });
        });

        context('with a data source id, database name and schema name, with sandbox datasets not shown', function() {
            beforeEach(function() {
                spyOn(this.dialog.schemaPicker, 'fieldValues').andReturn({
                    dataSource: "4",
                    databaseName: "new_database",
                    schemaName: "new_schema"
                });

                this.dialog.schemaPicker.trigger("change", "new_schema");
                this.dialog.$(".show_sandbox_datasets").prop("checked", false);
                this.dialog.$("button.submit").click();
            });

            it("sets the database name and schema name on the schema", function() {
                expect(this.dialog.model.get("databaseName")).toBe("new_database");
                expect(this.dialog.model.get("schemaName")).toBe("new_schema");
                expect(this.dialog.model.get("dataSourceId")).toBe("4");
            });

            it("saves the workspace with the new database and sandbox names", function() {
                expect(this.server.lastCreate().url).toBe('/workspaces/45/sandbox');
                var json = this.server.lastCreate().json()['sandbox'];
                expect(json['schema_name']).toBe('new_schema');
                expect(json['schema_id']).toBeUndefined();
                expect(json['database_name']).toBe('new_database');
                expect(json['data_source_id']).toBe('4');
                expect(json['show_sandbox_datasets']).toBe(false);
            });
        });
    });
});
