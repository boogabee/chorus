describe("chorus.views.SqlWorkfileContentDetails", function() {
    beforeEach(function() {
        this.model = backboneFixtures.workfile.sql({ fileName: 'test.sql', versionInfo: { content: "select * from foo" } });
        this.model.workspace().set({
            sandboxInfo: {
                id: 4,
                name: "schema",
                database: { id: 3, name: "db", dataSource: { id: 2, name: "data source" } }
            }
        });
        this.contentView = new chorus.views.SqlWorkfileContent({ model: this.model });
        spyOn(this.contentView, 'run');
        this.contentView.getSelectedText = function() {};

        this.view = new chorus.views.SqlWorkfileContentDetails({ model: this.model, contentView: this.contentView });
        this.qtipElement = stubQtip();
    });

    describe("render", function() {
        beforeEach(function() {
            this.view.render();
        });

        context("when the workfile does not have an execution schema", function() {
            beforeEach(function() {
                this.model = backboneFixtures.workfile.sql({ fileName: 'test.sql', versionInfo: { content: "select * from foo" } });
                this.model.set("executionSchema", null);
                this.view = new chorus.views.SqlWorkfileContentDetails({ model: this.model, contentView: this.contentView });
                this.view.render();
            });

            it("shows none as execution schema name", function() {
                expect(this.view.$(".execution_schema")).toContainTranslation("workfile.content_details.no_schema");
            });
        });

        it("shows the 'Run File' button", function() {
            expect(this.view.$('button.run_file')).toContainTranslation('workfile.content_details.run_file');
        });

        it("shows the execution schema name", function() {
            expect(this.view.$(".execution_schema")).toContainText(this.model.executionSchema().canonicalName());
        });

        it("puts the shortcuts next to the menu items", function() {
            expect(this.view.$("a.run_default").siblings(".menu_shortcut")).toContainText(Handlebars.helpers.hotKeyName("r"));
            expect(this.view.$("a.run_selection").siblings(".menu_shortcut")).toContainText(Handlebars.helpers.hotKeyName("e"));
        });

        context("when the workspace is archived", function() {
            beforeEach(function() {
                this.model.workspace().set({ archivedAt: "2012-05-08 21:40:14" });
                this.view.render();
            });

            it("should disable the 'Run File' menu", function() {
                expect(this.view.$(".run_file")).toBeDisabled();
            });
        });

        describe("permissions", function() {
            context("when user only has read and commenting permissions", function() {
                beforeEach(function() {
                    this.model.workspace().set({ permission: ["read", "commenting"] });
                    this.view.render();
                });

                it("should disable the 'Run File' ", function() {
                    expect(this.view.$(".run_file")).toBeDisabled();
                });

                it("should disable the 'Save' button", function() {
                    expect(this.view.$(".save button")).toBeDisabled();
                });

                it("should hide the 'change' button", function(){
                    expect(this.view.$(".change_workfile_schema")).not.toExist();
                });
            });

            context("when user has read, commenting, update permissions ", function() {
                beforeEach(function() {
                    this.model.workspace().set({ permission: ["read", "commenting", "update"] });
                    this.view.render();
                });
                it("should not disable the 'Run File' ", function() {
                    expect(this.view.$(".run_file")).not.toBeDisabled();
                });

                it("should not disable the 'Save' button", function() {
                    expect(this.view.$(".save button")).not.toBeDisabled();
                });
            });

            context("when user only has admin permissions", function() {
                beforeEach(function() {
                    this.model.workspace().set({ permission: ["admin"] });
                    this.view.render();
                });
                it("should not disabled the 'Run File' ", function() {
                    expect(this.view.$(".run_file")).not.toBeDisabled();
                });

                it("should not disable the 'Save' button", function() {
                    expect(this.view.$(".save button")).not.toBeDisabled();
                });
            });
        });

        context("when the user has not selected any text", function() {
            beforeEach(function() {
                this.contentView.getSelectedText = function() {
                    return "";
                };
                spyOn(chorus.PageEvents, "trigger").andCallThrough();
            });

            context("and opens the Run File menu", function() {
                beforeEach(function() {
                    this.view.$(".run_file").click();
                });

                it("disables the 'run selected sql' links in the menu", function() {
                    expect(this.qtipElement.find(".run_selection")).toHaveClass("disabled");
                    expect(this.qtipElement.find(".run_selection_and_download")).toHaveClass("disabled");
                });
            });

            it("the 'Save As' menu includes the 'Save file as a Chorus View' option", function() {
                this.view.$(".save_as").click();
                expect(this.qtipElement).toContainTranslation("workfile.content_details.save_as_chorus_view");
            });

            it("the 'Save as' menu includes the disabled 'Save selection as a Chorus View' option", function() {
                this.view.$(".save_as").click();
                expect(this.qtipElement).toContainTranslation("workfile.content_details.save_selection_as_chorus_view");
                expect(this.qtipElement.find("li a[data-menu-name='newSelectionChorusView']")).toHaveAttr('disabled');
            });
        });

        context("when the user has selected some text", function() {
            beforeEach(function() {
                spyOn(this.contentView, "getSelectedText").andReturn("Chuck and Lenny");
                spyOn(chorus.PageEvents, "trigger").andCallThrough();

                chorus.PageEvents.trigger("file:selectionPresent");
            });

            it("Changes the 'Run file' button text to 'Run Selected'", function() {
                expect(this.view.$(".run_file .run_description")).toContainTranslation("workfile.content_details.run_selected");
            });

            it("it enables the 'Save selection as a Chorus View' option", function() {
                this.view.$(".save_as").click();
                expect(this.qtipElement.find("li a[data-menu-name='newSelectionChorusView']")).not.toHaveAttr('disabled');
            });

            context("when the user de-selects text", function() {
                beforeEach(function() {
                    chorus.PageEvents.trigger("file:selectionEmpty");
                });

                it("changes Run Selected button text back to Run File", function() {
                    expect(this.view.$(".run_file .run_description")).toContainTranslation("workfile.content_details.run_file");
                });

                it("disables the 'Save selection as a Chorus View' option", function() {
                    this.view.$(".save_as").click();
                    expect(this.qtipElement.find("li a[data-menu-name='newSelectionChorusView']")).toHaveAttr('disabled');
                });
            });

            context("when the model has an execution schema", function() {
                describe("opening the Run File menu", function() {
                    beforeEach(function() {
                        this.view.$(".run_file").click();
                    });

                    it("enables the 'run selected sql' link in the menu", function() {
                        expect(this.qtipElement.find(".run_selection")).not.toHaveClass("disabled");
                        expect(this.qtipElement.find(".run_selection_and_download")).not.toHaveClass("disabled");
                    });

                    it("runs the selected sql when the user says to", function() {
                        this.qtipElement.find(".run_selection").click();
                        expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("file:runSelected");
                    });

                    context("clicking on 'Run selection and download'", function() {
                        it("launches the RunAndDownload dialog", function() {
                            var modalSpy = stubModals();
                            this.qtipElement.find('.run_selection_and_download').click();
                            expect(this.view.dialog.options.selection).toBeTruthy();
                            expect(modalSpy).toHaveModal(chorus.dialogs.RunAndDownload);
                        });
                    });
                });
            });

            context("when the model has no execution schema", function() {
                context("opening the Run File menu", function() {
                    beforeEach(function() {
                        this.model.set("executionSchema", null);
                        delete this.model._executionSchema;
                        this.view.render();
                        this.view.$(".run_file").click();
                    });

                    it("disables the 'run selected sql' link in the menu", function() {
                        expect(this.qtipElement.find(".run_selection")).toHaveClass("disabled");
                    });

                    it("has the right translation", function() {
                        expect(this.qtipElement.find(".run_selection")).toContainTranslation("workfile.content_details.run_selection");
                    });

                    it("does nothing when the user clicks run selection", function() {
                        chorus.PageEvents.trigger.reset();
                        this.qtipElement.find(".run_selection").click();
                        expect(chorus.PageEvents.trigger).not.toHaveBeenCalled();
                    });
                });
            });
        });

        context("opening the Run File menu", function() {
            beforeEach(function() {
                this.view.$(".run_file").click();
            });

            describe("when the workfile does not have an execution schema", function() {
                beforeEach(function() {
                    this.model.set("executionSchema", null);
                    delete this.model._executionSchema;
                    this.view.render();
                    this.view.$(".run_file").click();
                });

                it("disables the 'run file' link", function() {
                    var runLink = this.qtipElement.find(".run_default");
                    expect(runLink).toContainTranslation("workfile.content_details.run");
                    expect(runLink).toBe("span");
                });

                it("disables the 'run and download ' link", function() {
                    var runAndDownloadLink = this.qtipElement.find(".run_and_download");
                    expect(runAndDownloadLink).toContainTranslation("workfile.content_details.run_and_download");
                    expect(runAndDownloadLink).toBe("span");
                });

                it("does nothing when the disabled span is clicked", function() {
                    spyOn(chorus.PageEvents, "trigger").andCallThrough();
                    this.qtipElement.find(".run_default").click();
                    expect(chorus.PageEvents.trigger).not.toHaveBeenCalled();
                });
            });

            context("clicking on 'Run file'", function() {
                beforeEach(function() {
                    spyOn(chorus.PageEvents, "trigger").andCallThrough();
                    this.qtipElement.find('.run_default').click();
                });

                it("triggers the 'file:runCurrent' event on the view", function() {
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("file:runCurrent");
                });
            });

            context("clicking on 'Run file and download'", function() {
                it("launches the RunAndDownload dialog", function() {
                    var modalSpy = stubModals();
                    this.qtipElement.find('.run_and_download').click();
                    expect(this.view.dialog.options.selection).toBeFalsy();
                    expect(modalSpy).toHaveModal(chorus.dialogs.RunAndDownload);
                });
            });

            context("it fires an event - editorSelectionStatus", function() {
                beforeEach(function() {
                    spyOn(this.contentView, "getSelectedText").andReturn("Chuck and Lenny");
                    spyOn(chorus.PageEvents, "trigger").andCallThrough();
                    this.qtipElement.find('.run_default').click();
                    this.view.render();
                });

                it("trigger the event", function() {
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("file:editorSelectionStatus");
                });
            });
        });

        describe("clicking the change button", function(){
            var modalSpy;
            beforeEach(function() {
                modalSpy = stubModals();
                this.saveDraftSpy = jasmine.createSpy("saveDraft");
                chorus.PageEvents.on('file:saveDraft', this.saveDraftSpy);

                this.view.$(".change_workfile_schema").click();
            });

            it("triggers a 'file:saveDraft' page event", function() {
                expect(this.saveDraftSpy).toHaveBeenCalled();
            });

            it("shows the change schema dialog", function(){
                expect(modalSpy).toHaveModal(chorus.dialogs.ChangeWorkfileSchema);
            });
        });
    });

    describe("event handling", function() {

        describe("a.change_workfile_schema:clicked", function() {
            beforeEach(function() {
                this.view.render();
                spyOn(this.view, "changeWorkfileSchema");
                this.view.delegateEvents();
                this.view.$("a.change_workfile_schema").click();
            });
            it("calls the changeWorkfileSchema function", function() {
                expect(this.view.changeWorkfileSchema).toHaveBeenCalled();
            });
        });
    });

    describe("create chorus view", function() {
        beforeEach(function() {
            stubModals();
            this.view.model.workspace().set({active: true});
            spyOn(chorus.PageEvents, "trigger").andCallThrough();
        });

        describe("from file", function() {
            beforeEach(function() {
                this.view.render();
                chorus.PageEvents.trigger('file:selectionEmpty');
            });

            it("triggers file:newChorusView", function() {
                this.view.$('.save_as').click();
                this.qtipElement.$('a[data-menu-name="newChorusView"]').click();
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("file:newChorusView");
            });
        });

        it("it disables the Chorus View creation menu if no valid schema", function() {
            this.view.model.attributes.executionSchema = null;
            spyOn(this.view.model.workspace(), 'sandbox').andReturn(null);
            this.view.render();

            this.view.$('.save_as').click();
            expect(this.qtipElement.$('a[data-menu-name="newChorusView"]')).toHaveAttr('disabled');
        });

        context("with a selection", function() {
            it("triggers file:newSelectionChorusView", function() {
                this.view.render();
                chorus.PageEvents.trigger('file:selectionPresent');
                this.view.$('.save_as').click();
                this.qtipElement.$('a[data-menu-name="newSelectionChorusView"]').click();

                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("file:newSelectionChorusView");
            });

            context("there is no sandbox nor executionSchema", function() {
                it("disables the Chorus View creation menu", function() {
                    this.view.model.attributes.executionSchema = null;
                    spyOn(this.view.model.workspace(), 'sandbox').andReturn(null);

                    this.view.render();
                    chorus.PageEvents.trigger('file:selectionPresent');

                    this.view.$('.save_as').click();
                    expect(this.qtipElement.$('a[data-menu-name="newSelectionChorusView"]')).toHaveAttr('disabled');
                });
            });
        });
    });
});
