describe("chorus.dialogs.RenameWorkfile", function() {
    context("when the workfile is sql", function() {
        beforeEach(function(){
            this.workfile = backboneFixtures.workfile.sql({fileName: "originalName.sql"});
            this.dialog = new chorus.dialogs.RenameWorkfile({model: this.workfile});
            this.dialog.render();
        });

        it("should have an input field containing the current file name", function(){
            expect(this.dialog.$('input').val()).toBe("originalName");
        });

        it("should display a different version of the dialog", function() {
            expect(this.dialog.additionalContext().isSql).toBeTruthy();
        });

        context("submitting the form", function() {
            beforeEach(function(){
                spyOn(this.workfile, 'save').andCallThrough();
                this.dialog.$('input').val("newName").change();
                this.dialog.$("form").submit();
            });

            it ("should append .sql to the fileName", function() {
                expect(this.workfile.save).toHaveBeenCalledWith({fileName: 'newName.sql'}, {wait: true});
            });
        });
    });

    beforeEach(function() {
        this.workfile = backboneFixtures.workfile.image({fileName: "originalName"});
        this.dialog = new chorus.dialogs.RenameWorkfile({model: this.workfile});
        this.dialog.render();
    });

    it("should have content that says to change file name", function(){
        expect(this.dialog.title).toMatchTranslation("workfile.rename_dialog.title");
    });

    it("should have an input field containing the current file name", function(){
        expect(this.dialog.$('input').val()).toBe("originalName");
    });

    context("with invalid form values", function() {
        beforeEach(function() {
            spyOn(this.dialog, "create");
            this.dialog.$('input').val("").keyup();
        });

        it("does not let you submit the form when clicking the button", function() {
            expect(this.dialog.$("button.submit")).toBeDisabled();
        });

        it("does not let you submit the form when hitting enter", function() {
            this.dialog.$("form").submit();
            expect(this.dialog.create).not.toHaveBeenCalled();
        });
    });

    describe("submitting the form", function() {
        beforeEach(function() {
            spyOn(this.dialog, "closeModal");
            spyOn(this.workfile, 'save').andCallThrough();
            spyOnEvent(this.dialog.model, "change");
            this.dialog.$('input').val("newName.sql").change();
            this.dialog.$("form").submit();
        });

        it("should not change the fileName elsewhere until the save completes", function() {
            expect("change").not.toHaveBeenTriggeredOn(this.dialog.model);
        });

        it("should update the workfile", function() {
            expect(this.workfile.save).toHaveBeenCalledWith({fileName: 'newName.sql'}, {wait: true});
        });

        it("should be loading", function() {
            expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
        });

        context("when the save is successful", function() {
            beforeEach(function() {
                spyOnEvent(chorus.PageEvents, "workfile:rename");
                this.server.lastUpdate().succeed({fileName: "anotherNameThatMakesPerfectSense"});
            });

            it("closes the modal", function() {
                expect(this.dialog.closeModal).toHaveBeenCalled();
            });

            it("re-renders", function() {
                expect("change").toHaveBeenTriggeredOn(this.dialog.model);
            });

            it("triggers a page event", function() {
                expect("workfile:rename").toHaveBeenTriggeredOn(chorus.PageEvents);
            });

        });

        context("when the save fails", function() {
            beforeEach(function() {
                this.server.lastUpdate().failUnprocessableEntity();
            });

            it("stops the loading spinner", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
            });

            it("retains the original file name", function() {
                expect(this.dialog.model.name()).toBe("originalName");
            });

            it("keeps the invalid name in the input", function() {
                expect(this.dialog.$("input").val()).toBe("newName.sql");
            });
        });
    });
});