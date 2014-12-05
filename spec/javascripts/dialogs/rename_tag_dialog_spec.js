describe("chorus.dialogs.RenameTag", function() {
    beforeEach(function() {
        this.tag = new chorus.models.Tag({name: "testTag", id: 123});
        this.dialog = new chorus.dialogs.RenameTag({model: this.tag});
        this.dialog.render();
        this.input = this.dialog.$el.find('.rename_tag_input');
    });

    describe("#render", function() {
        it("has the tag's name in the text field", function() {
            expect(this.input).toHaveValue("testTag");
        });
    });

    describe("submitting a new tag name", function() {
        beforeEach(function() {
            spyOnEvent(this.tag, "change");
            spyOnEvent($(document), "close.facebox");
            this.input.val("new-tag-name");
            this.dialog.$('form').submit();
        });

        it("does not close the dialog before the server responds", function() {
            expect("close.facebox").not.toHaveBeenTriggeredOn($(document));
        });

        it("should display a loading spinner in the submit button", function() {
            expect(this.dialog.$("button[type=submit]")).toHaveSpinner();
            expect(this.dialog.$("button[type=submit]")).toContainTranslation("actions.renaming");
        });

        context("when the save is successful", function() {
            beforeEach(function() {
                spyOn(chorus, "toast");
                this.server.completeUpdateFor(this.tag, this.tag.attributes);
            });

            it("closes the dialog", function() {
                expect("close.facebox").toHaveBeenTriggeredOn($(document));
            });

            it("triggers change on the tag model", function() {
                expect("change").toHaveBeenTriggeredOn(this.tag);
            });

            it("displays a toast message", function() {
                expect(chorus.toast).toHaveBeenCalledWith("tag.rename", {name: "new-tag-name"});
            });
        });

        context("when the server request fails with an unprocessable entity failure", function() {
            beforeEach(function(){
                this.input.val("new-tag-name");
                this.dialog.$('form').submit();
                spyOnEvent(this.tag, "unprocessableEntity");
                this.server.lastUpdate().failUnprocessableEntity();
            });

            it("displays a server error in the dialog", function() {
                expect(this.dialog.$(".errors")).not.toHaveClass("hidden");
            });

            it("does not call the model's default error handler", function() {
                expect("unprocessableEntity").not.toHaveBeenTriggeredOn(this.tag);
            });

            it("stops the spinner", function() {
                expect(this.dialog.$("button[type=submit]")).not.toHaveSpinner();
            });

            it("does not trigger change on the tag model", function() {
                expect("change").not.toHaveBeenTriggeredOn(this.tag);
            });
        });
    });

    describe("validating input as user types", function() {
        it("enables the button for a new name", function() {
            this.input.val("different-name").keyup();
            expect(this.dialog.$("button[type=submit]")).not.toBeDisabled();
        });

        it("disables the button initially because the name hasn't changed", function() {
            expect(this.dialog.$("button[type=submit]")).toBeDisabled();
        });

        it("disables the button when the name is cleared", function() {
            this.input.val("").keyup();
            expect(this.dialog.$("button[type=submit]")).toBeDisabled();
        });

        it("displays a validation error when tag name is too long", function() {
            this.input.val(_.repeat("a", 101)).keyup();
            expect(this.dialog.$("button[type=submit]")).toBeDisabled();
            expect(this.input).toHaveClass("has_error");
        });

        context("after an error is displayed", function() {
            it("clears the errors when a new value is entered", function() {
                this.input.val("").keyup();
                expect(this.input).toHaveClass("has_error");

                this.input.val("a-good-tag").keyup();
                expect(this.dialog.$("button[type=submit]")).not.toBeDisabled();
                expect(this.input).not.toHaveClass("has_error");
            });
        });
    });
});