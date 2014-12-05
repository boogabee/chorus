describe("chorus.dialogs.WorkfilesSqlNew", function() {
    beforeEach(function() {
        this.workspace = backboneFixtures.workspace();
        this.dialog = new chorus.dialogs.WorkfilesSqlNew({ pageModel: this.workspace });
    });

    it("does not re-render when the model changes", function() {
        expect(this.dialog.persistent).toBeTruthy();
    });

    describe("#render", function() {
        beforeEach(function() {
            this.dialog.render();
        });

        it("starts with the submit button disabled", function() {
            expect(this.dialog.$("button.submit")).toBeDisabled();
        });

        describe("filling out filename", function() {
            beforeEach(function() {
                this.dialog.$("input[name=fileName]").val("An hero.sql").keyup();
            });

            it("has enabled the submit button", function() {
                expect(this.dialog.$("button.submit")).not.toBeDisabled();
            });

            it("disables the button when the name is cleared", function() {
                this.dialog.$("input[name=fileName]").val("").keyup();
                expect(this.dialog.$("button.submit")).toBeDisabled();
            });
        });
    });

    describe("submit", function() {
        beforeEach(function() {
            this.dialog.render();
        });

        context("with invalid form values", function() {
            beforeEach(function() {
                this.dialog.$("form").submit();
            });

            it("does not let you submit the form", function() {
                expect(this.dialog.$('form input[name=fileName]')).toHaveText("");
                expect(this.dialog.$("form button.submit")).toBeDisabled();
            });
        });

        context("with valid form values", function() {
            beforeEach(function() {
                this.dialog.$("input[name=fileName]").val("   awesomesqlfile   ");
                this.dialog.$("form").submit();
            });

            it('sets the source to "empty"', function() { //Of course it does.
                expect(this.dialog.model.get("source")).toBe("empty");
            });

            it("sets the fileName to the trimmed file name with extension", function() {
                expect(this.dialog.model.get("fileName")).toBe("awesomesqlfile.sql");
            });

            it("posts to the correct URL", function() {
                expect(this.server.requests[0].url).toBe("/workspaces/" + this.workspace.id + "/workfiles");
            });

            it("puts the button in the loading state", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
            });

            context("when save is successful", function() {
                beforeEach(function() {
                    spyOn(chorus.router, "navigate");
                    spyOnEvent($(document), "close.facebox");
                    this.server.completeCreateFor(this.dialog.model, _.extend({}, this.dialog.model.attributes, {
                        fileType: 'SQL',
                        id: '10108'
                    }));
                });

                it("redirects to the new workspace show page", function() {
                    expect(chorus.router.navigate).toHaveBeenCalledWith("#/workspaces/" + this.workspace.id + "/workfiles/10108");
                });

                it("dismisses the dialog", function() {
                    expect("close.facebox").toHaveBeenTriggeredOn($(document));
                });
            });

            context("when save fails", function() {
                beforeEach(function() {
                    this.dialog.model.serverErrors = { fields: { a: { BLANK: {} } } };
                    this.dialog.model.trigger("saveFailed");
                });

                it("displays the errors and does not leave the button in the loading state", function() {
                    expect(this.dialog.$(".errors").text()).toContain("A can't be blank");
                    expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
                });

                context("with an invalid name error", function() {
                    beforeEach(function() {
                        this.dialog.model.serverErrors = { fields: { fileName: { INVALID: {} } } };
                        this.dialog.model.trigger("saveFailed");
                    });

                    it("displays the errors and does not leave the button in the loading state", function() {
                        expect(this.dialog.$(".errors").text()).toContain("File name is invalid");
                        expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
                    });
                });
            });
        });
    });
});
