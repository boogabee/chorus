describe("chorus.dialogs.SchemaPicker", function() {
    beforeEach(function() {
        this.dialog = new chorus.dialogs.SchemaPicker({ action: "select_import_schema" });
        this.dialog.render();
    });

    describe("#render", function() {
        it("has the right title", function() {
            expect(this.dialog.$(".dialog_header h1")).toContainTranslation("schema_picker.select_import_schema.title");
        });

        it("has a disabled Select Schema button", function() {
            expect(this.dialog.$("button.submit").text().trim()).toMatchTranslation("schema_picker.select_import_schema.save");
            expect(this.dialog.$("button.submit")).toBeDisabled();
        });

        it("has a Cancel button", function() {
            expect(this.dialog.$("button.cancel").text().trim()).toMatchTranslation("actions.cancel");
        });
    });

    describe("with a pre-selected schema", function() {
        beforeEach(function() {
            this.schema = backboneFixtures.schema();
            this.dialog = new chorus.dialogs.SchemaPicker({ action: "select_import_schema", schema: this.schema });
            this.dialog.render();
        });

        it("pre-selects that schema", function() {
            expect(this.dialog.schemaPicker.options.defaultSchema).toEqual(this.schema);
        });
    });

    context("when the schema picker is ready", function() {
        beforeEach(function() {
            spyOn(this.dialog.schemaPicker, "ready").andReturn(true);
            this.dialog.schemaPicker.trigger("change");
        });

        it("enables the save schema button", function() {
            expect(this.dialog.$("button.submit")).toBeEnabled();
        });
    });

    context("clicking submit", function() {
        beforeEach(function() {
            spyOn(this.dialog.schemaPicker, "ready").andReturn(true);
            this.dialog.schemaPicker.trigger("change");
        });

        it("triggers schema:selected when submit is clicked", function() {
            this.schema = backboneFixtures.schema();
            spyOn(this.dialog.schemaPicker, "getSelectedSchema").andReturn(this.schema);

            this.selectedSpy = jasmine.createSpy("schemaSelected");
            this.dialog.on("schema:selected", this.selectedSpy);

            this.dialog.$("button.submit").click();
            expect(this.selectedSpy).toHaveBeenCalledWith(this.schema);
        });

        it("closes the dialog", function() {
            spyOn(this.dialog, "closeModal");
            this.dialog.$("button.submit").click();
            expect(this.dialog.closeModal).toHaveBeenCalled();
        });
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
});
