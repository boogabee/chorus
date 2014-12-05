describe("chorus.dialogs.SqlPreview", function () {
    describe("#render", function () {
        beforeEach(function () {
            var model = backboneFixtures.workspaceDataset.chorusView({query: "select awesome from sql"});
            this.dialog = new chorus.dialogs.SqlPreview({ model: model });
            spyOn(CodeMirror, 'fromTextArea').andReturn({ refresh: $.noop });

            stubModals();
            this.dialog.launchModal();
        });

        it("has a close window button", function () {
            expect(this.dialog.$('.form_controls button.cancel')).toExist();
            expect(this.dialog.$('.form_controls button.cancel').text().trim()).toMatchTranslation("actions.close_window");
        });

        it("hides the sql text area until the codemirror editor is ready", function () {
            var textarea = this.dialog.$("textarea");
            expect(textarea).toHaveClass("hidden");
            var deferredFn = _.delay.nthCall(0).args[0];
            deferredFn();
            expect(CodeMirror.fromTextArea).toHaveBeenCalled();
            expect(CodeMirror.fromTextArea.lastCall().args[0]).toBe(textarea[0]);
        });

        it("hides the data preview area", function () {
            expect(this.dialog.$(".results_console")).toHaveClass("hidden");
        });

        describe("preview bar", function () {
            it("has a link to 'Data Preview'", function () {
                expect(this.dialog.$("button.preview")).toExist();
            });

            describe("opening the Data Preview", function () {
                beforeEach(function () {
                    this.dialog.$("button.preview").click();
                });

                it("sends the data preview command", function () {
                    expect(this.server.lastCreateFor(this.dialog.resultsConsole.model)).toBeDefined();
                });

                describe("when the data preview succeeds", function () {
                    beforeEach(function () {
                        this.server.completeCreateFor(this.dialog.resultsConsole.model, backboneFixtures.dataPreviewTaskResults());
                    });

                    it("shows the result table", function () {
                        expect(this.dialog.$(".result_table")).not.toHaveClass("hidden");
                    });

                    it("hides the preview button", function () {
                        expect(this.dialog.$("button.preview")).toHaveClass("invisible");
                    });

                    it("shows the expander", function () {
                        expect(this.dialog.$(".expander_button")).toExist();
                    });

                    describe("closing the Data Preview", function () {
                        beforeEach(function () {
                            this.dialog.$(".results_console .close").click();
                        });

                        it("does not show the Data Preview any longer", function () {
                            expect(this.dialog.$(".results_console")).toHaveClass("hidden");
                        });

                        it("shows the preview button", function () {
                            expect(this.dialog.$("button.preview")).not.toHaveClass("invisible");
                        });

                        describe("clicking on the data preview again", function () {
                            beforeEach(function () {
                                this.dialog.$("button.preview").click();
                            });

                            it("shows the result console", function () {
                                expect(this.dialog.$(".results_console")).not.toHaveClass("hidden");
                            });
                        });
                    });
                });
            });
        });

        describe("generated sql", function () {
            it("constructs the SQL correctly", function () {
                expect(this.dialog.$("textarea").val()).toBe("select awesome from sql");
            });
        });

        describe("clicking the close button", function () {
            beforeEach(function () {
                spyOn(this.dialog.resultsConsole, "cancelExecution");
                this.dialog.$("button.cancel").click();
            });

            it("cancels the task", function () {
                expect(this.dialog.resultsConsole.cancelExecution).toHaveBeenCalled();
            });
        });

        describe("dismissing the dialog any other way", function () {
            beforeEach(function () {
                spyOn(this.dialog.resultsConsole, "cancelExecution");
                this.dialog.modalClosed();
            });

            it("cancels the task", function () {
                expect(this.dialog.resultsConsole.cancelExecution).toHaveBeenCalled();
            });
        });
    });
});
