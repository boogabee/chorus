describe("chorus.dialogs.EditNote", function() {
    beforeEach(function() {
        unstubClEditor();
        this.text = "Hi i'm a friendly text";
        this.note = backboneFixtures.activity.noteOnGreenplumDataSource({
            body: this.text
        });
        this.note.collection = new chorus.collections.ActivitySet([]);
        this.dialog = new chorus.dialogs.EditNote({ activity: this.note });
        $('#jasmine_content').append(this.dialog.el);

        spyOn(this.dialog, "makeEditor").andCallThrough();

        this.dialog.render();
    });

    it("displays 'edit this note' as the title", function() {
        expect(this.dialog.$('h1').text()).toMatchTranslation("notes.edit_dialog.note_title");
    });

    context("when the activity is an insight", function() {
        beforeEach(function() {
            this.note = backboneFixtures.activity.insightOnGreenplumDataSource();
            this.dialog = new chorus.dialogs.EditNote({ activity: this.note });
            $('#jasmine_content').append(this.dialog.el);
            this.dialog.render();
        });

        it("displays 'edit this insight' as the title", function() {
            expect(this.dialog.$('h1').text()).toMatchTranslation("notes.edit_dialog.insight_title");
        });
    });

    it("has the right text in the buttons", function() {
        expect(this.dialog.$("button.submit").text()).toMatchTranslation("actions.save_changes");
        expect(this.dialog.$("button.cancel").text()).toMatchTranslation("actions.cancel");
    });

    it("has the text field, containing the user's previously entered text'", function() {
        expect(this.dialog.$('textarea').val()).toContain(this.text);
    });

    it("makes a cl editor with toolbar", function() {
        expect(this.dialog.$('.toolbar')).toExist();
        expect(this.dialog.makeEditor).toHaveBeenCalled();
        var editorArgs = this.dialog.makeEditor.lastCall().args;

        expect(editorArgs[0]).toBe(this.dialog.el);
        expect(editorArgs[1]).toBe(".toolbar");
        expect(editorArgs[2]).toBe("body");
        expect(editorArgs[3]).toEqual({ width : 'auto', height : 150, controls : 'bold italic | bullets numbering | link unlink' });
    });

    describe("submitting the form with a blank body", function() {
        it("shows errors when form is blank", function() {
            this.dialog.$("textarea").val("");
            this.dialog.$("button.submit").click();

            expect(this.dialog.model.errors.body).toEqual("Note is required");
            expect(this.dialog.$(".cleditorMain")).toHaveClass("has_error");
        });

        it("shows errors when form is just a <br>", function() {
            this.dialog.$("textarea").val("<br>");
            this.dialog.$("button.submit").click();

            expect(this.dialog.model.errors.body).toEqual("Note is required");
            expect(this.dialog.$(".cleditorMain")).toHaveClass("has_error");
        });

        it("shows errors when form is just HTML whitespaces", function() {
            this.dialog.$("textarea").val("&nbsp;&nbsp;");
            this.dialog.$("button.submit").click();

            expect(this.dialog.model.errors.body).toEqual("Note is required");
            expect(this.dialog.$(".cleditorMain")).toHaveClass("has_error");
        });


        it("shows errors when form is just a lot of whitespaces", function() {
            this.dialog.$("textarea").val("                     ");
            this.dialog.$("button.submit").click();

            expect(this.dialog.model.errors.body).toEqual("Note is required");
            expect(this.dialog.$(".cleditorMain")).toHaveClass("has_error");
        });
    });

    describe("submitting the form", function() {
        beforeEach(function() {
            this.dialog.$("textarea").val("Agile, meet big data. Let's pair.");
            spyOn($.fn, "stopLoading").andCallThrough();
            this.dialog.$("button.submit").click();
        });

        it("starts a spinner", function() {
            expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
            expect(this.dialog.$("button.submit").text()).toContainTranslation("actions.saving");
        });

        it("updates the note correctly", function() {
            var note = this.note.toNote();
            expect(note).toHaveBeenUpdated();
            var update = this.server.lastUpdateFor(note);
            expect(update.json()["note"]["body"]).toBe("Agile, meet big data. Let's pair.");
        });

        describe("when the save completes successfully", function() {
            beforeEach(function() {
                spyOn(this.dialog, "closeModal");
                spyOn(chorus.PageEvents, "trigger");
                this.server.lastUpdate().succeed();
            });

            it("closes the dialog", function() {
                expect(this.dialog.closeModal).toHaveBeenCalled();
            });

            it('triggers the note:saved event', function() {
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith('note:saved', this.dialog.model);
            });
        });

        context("when the save fails", function() {
            beforeEach(function() {
                spyOn(this.dialog, "closeModal");

                this.dialog.model.trigger("saveFailed");
            });

            it("does not close the dialog box", function() {
                expect(this.dialog.closeModal).not.toHaveBeenCalled();
            });

            it("removes the spinner from the button", function() {
                expect($.fn.stopLoading).toHaveBeenCalledOnSelector("button.submit");
            });
        });
    });

});
