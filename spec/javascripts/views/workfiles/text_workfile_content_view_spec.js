describe("chorus.views.TextWorkfileContentView", function() {
    stubKeyboardMetaKey();
    beforeEach(function() {
        chorus._navigated();
        this.textfile = backboneFixtures.workfile.text();
        spyOn(this.textfile.workspace(), 'isActive').andReturn(true);
        this.view = new chorus.views.TextWorkfileContent({model: this.textfile, hotkeys: { 'r': 'some:event' }});
        this.saveInterval = this.view.saveInterval;
        $("#jasmine_content").append(this.view.el);
        this.clock = this.useFakeTimers();

        // in IE8, we can't 'select' a textrange whose textarea is not on the DOM
        if($.browser.msie) {
            spyOn(window.TextRange.prototype, 'select');
        }
        spyOn(CodeMirror, "fromTextArea").andCallThrough();
    });

    describe("hotkey options", function() {
        beforeEach(function() {
            this.view = new chorus.views.TextWorkfileContent({model: this.textfile, hotkeys: {a: "whatever", b: "something_else"}});
            this.view.render();
        });

        it("correctly sets the extraKeys on the CodeMirror options", function() {
            var opts = CodeMirror.fromTextArea.lastCall().args[1];
            expect(opts.extraKeys["Ctrl-Space"]).toBe("autocomplete");
            expect(opts.extraKeys["Shift-Space"]).toBe("autocomplete");
            expect(opts.extraKeys[_.str.capitalize(chorus.hotKeyMeta) + "-A"]).toBeDefined();
            expect(opts.extraKeys[_.str.capitalize(chorus.hotKeyMeta) + "-B"]).toBeDefined();
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view.render();
        });

        describe("#editable", function() {
            it("set the file to be editable", function() {
                spyOn(this.textfile, "canEdit").andReturn(true);
                this.view = new chorus.views.TextWorkfileContent({model: this.textfile});
                this.view.render();
                expect(this.view.editor.getOption("readOnly")).toBe(false);
            });

            it("set the file to be not editable", function() {
                spyOn(this.textfile, "canEdit").andReturn(false);
                this.view = new chorus.views.TextWorkfileContent({model: this.textfile});
                this.view.render();
                expect(this.view.editor.getOption("readOnly")).toBe("nocursor");
            });
        });

        it("displays line numbers", function() {
            expect(this.view.editor.getOption("lineNumbers")).toBe(true);
        });

        it("displays the text file content", function() {
            expect(this.view.editor.getValue()).toBe(this.textfile.content());
        });

        it("uses the 'text/plain' mode for plain text files", function() {
            expect(this.view.editor.getOption("mode")).toBe("text/plain");
        });

        it("triggers a Ctrl+R keydown on the document when Ctrl+R keydown is received by the editor", function() {
            spyOn(chorus, "triggerHotKey");
            this.view.editor.editor.triggerOnKeyDown({ ctrlKey: true, keyCode: 82 });
            expect(chorus.triggerHotKey).toHaveBeenCalledWith('r');
        });

        context("determining syntax highlighting", function() {
            beforeEach(function() {
                spyOn(chorus.utilities, "mime").and.callThrough();
            });

            it("uses the 'text/x-plsql' mode for sql files", function() {
                this.textfile.set({ fileType: "sql", fileName: "sweet.sql" });
                this.view = new chorus.views.TextWorkfileContent({model: this.textfile});
                this.view.render();
                expect(chorus.utilities.mime).toHaveBeenCalledWith("sql");
                expect(this.view.editor.getOption("mode")).toBe("text/x-plsql");
            });

            it("uses the 'text/x-ruby' mode for rb files", function() {
                this.textfile.set({ fileType: "code", fileName: "sweet.rb" });
                this.view = new chorus.views.TextWorkfileContent({model: this.textfile});
                this.view.render();
                expect(chorus.utilities.mime).toHaveBeenCalledWith("rb");
                expect(this.view.editor.getOption("mode")).toBe("text/x-ruby");
            });
        });
    });

    describe("#render when read-only", function() {
        beforeEach(function() {
            spyOn(this.textfile, "canEdit").andReturn(false);
            this.view = new chorus.views.TextWorkfileContent({model: this.textfile});
            this.view.render();
        });

        it("has no save button", function() {
            expect(this.view.$("button")).not.toExist();
        });

        it("has read-only content area", function() {
            expect(this.view.editor.getOption("readOnly")).toBe("nocursor");
        });
    });

    describe("#editText", function() {
        beforeEach(function() {
            this.view.render();

            this.view.editor.setCursor(500, 500);
            spyOn(this.view.editor, "focus");
            this.view.editText();
        });

        afterEach(function() {
            this.view.replaceCurrentVersion();
        });

        it("sets readonly to false", function() {
            expect(this.view.editor.getOption("readOnly")).toBe(false);
        });

        it("focuses on the editable text", function() {
            expect(this.view.editor.focus).toHaveBeenCalled();
        });

        it("puts the cursor at the end of the file", function() {
            var coords = this.view.editor.getCursor();
            expect(coords.line).toBe(9);
            expect(coords.ch).toBe(0);
        });

        it("adds the editable class to the CodeMirror div", function() {
            expect(this.view.$(".CodeMirror")).toHaveClass("cm-s-editable");
        });
    });

    describe("#autosave", function() {
        beforeEach(function() {
            this.view.render();
        });

        describe("when the file is changed", function() {
            beforeEach(function() {
                this.view.editor.setValue("Foo, Bar");
            });

            describe("when the file is changed again", function() {
                beforeEach(function() {
                    this.clock.tick(10);
                    this.view.editor.setValue("Foo, Bar, Baz");
                });

                describe("when the timeout elapses", function() {
                    beforeEach(function() {
                        this.clock.tick(this.saveInterval);
                    });

                    it("only saves the file once", function() {
                        expect(this.server.lastCreate().json()['workfile_draft']['content']).toEqual("Foo, Bar, Baz");
                        expect(this.server.updates().length).toBe(0);
                    });
                });
            });

            describe("when the timeout elapses", function() {
                beforeEach(function() {
                    this.clock.tick(this.saveInterval);
                });

                it("creates a draft", function() {
                    expect(this.server.lastCreate().json()['workfile_draft']['content']).toEqual("Foo, Bar");
                    expect(this.server.updates().length).toBe(0);
                });

                describe("when the timeout elapses again, with no changes", function() {
                    beforeEach(function() {
                        this.clock.tick(this.saveInterval);
                    });

                    it("does not save the draft again", function() {
                        expect(this.server.lastCreate().json()['workfile_draft']['content']).toEqual("Foo, Bar");
                        expect(this.server.updates().length).toBe(0);
                    });
                });

                describe("when the timeout elapses again after the file is changed again", function() {
                    beforeEach(function() {
                        this.server.lastCreate().succeed([]);
                        // start timer directly to imply change on code mirror
                        this.view.startTimer();
                        this.clock.tick(this.saveInterval);
                    });

                    it("updates the draft", function() {
                        expect(this.server.lastCreate().json()['workfile_draft']['content']).toEqual("Foo, Bar");
                        expect(this.server.lastUpdate().json()['workfile_draft']['content']).toEqual("Foo, Bar");
                    });
                });
            });
        });
    });

    describe("the 'file:saveDraft' event", function() {
        beforeEach(function() {
            spyOn(this.view.model, "createDraft").andCallThrough();
            chorus.PageEvents.trigger("file:saveDraft");
        });

        it("saves the draft", function() {
            expect(this.view.model.createDraft).toHaveBeenCalled();
        });
    });

    describe("saving the workfile", function() {
        beforeEach(function() {
            this.textfile.content("old content");
            this.textfile.set({"latestVersionNum": 2});

            this.view.render();
            this.view.editText();
            this.view.editor.setValue('This should be a big enough text, okay?');
            this.view.editor.setCursor(0, 19);

            this.modalSpy = stubModals();

            spyOn(this.view, "stopTimer");
            spyOn(this.textfile, "save").andCallThrough();
            spyOn(this.view, "editText").andCallThrough();
            spyOn(this.textfile, "canEdit").andReturn(true);
        });

        describe("the 'file:replaceCurrentVersion' event", function() {
            context("when there is no modal", function(){
                beforeEach(function() {
                    chorus.modal = null;
                    chorus.PageEvents.trigger("file:replaceCurrentVersion");
                    this.clock.tick(10000);
                });

                it("calls save", function() {
                    expect(this.view.model.save).toHaveBeenCalled();
                });

                it("sets cursor at the correct position", function() {
                    expect(this.view.editor.getCursor().ch).toBe(19);
                    expect(this.view.editor.getCursor().line).toBe(0);
                });

                it("sets readonly to nocursor", function() {
                    expect(this.view.editor.getOption("readOnly")).toBe(false);
                });

                it("saves the selected content only", function() {
                    expect(this.view.model.content()).toBe('This should be a big enough text, okay?');
                });

                it("maintains the editor in edit mode", function() {
                    expect(this.view.$(".CodeMirror")).toHaveClass("cm-s-editable");
                });

                context("when there is a version conflict", function() {
                    it("shows the version conflict alert", function() {
                        this.server.lastUpdate().failUnprocessableEntity({fields: {version: {INVALID: {}}}});

                        expect(this.modalSpy).toHaveModal(chorus.alerts.WorkfileConflict);
                    });
                });

                context("when you are replacing a deleted version", function() {
                    it("shows the version conflict alert", function() {
                        this.server.lastUpdate().failNotFound();
                        expect(this.modalSpy).toHaveModal(chorus.alerts.WorkfileConflict);
                    });
                });
            });

            context("when a modal is open", function(){
                beforeEach(function(){
                    chorus.PageEvents.trigger("file:replaceCurrentVersion");
                });

                it('does not move focus from the modal to the text editor', function() {
                    expect(this.view.editText).not.toHaveBeenCalled();
                });
            });
        });

        describe("event file:createNewVersion", function() {
            beforeEach(function() {
                chorus.PageEvents.trigger("file:createNewVersion");
            });

            it("calls stops the auto save timer", function() {
                expect(this.view.stopTimer).toHaveBeenCalled();
            });

            it("updates the model", function() {
                expect(this.view.model.content()).toBe("This should be a big enough text, okay?");
            });

            it("launches the 'save workfile as new version' dialog with the correct model", function() {
                expect(this.modalSpy).toHaveModal(chorus.dialogs.WorkfileNewVersion);
                expect(this.view.dialog.model).toBeA(chorus.models.Workfile);
            });
        });

        context("with text selected", function() {
            beforeEach(function() {
                this.view.editor.setSelection({line: 0, ch: 17}, {line: 0, ch: 20});
            });

            describe("the 'file:replaceCurrentVersionWithSelection' event", function() {
                beforeEach(function() {
                    chorus.modal = null;
                    chorus.PageEvents.trigger("file:replaceCurrentVersionWithSelection");
                    this.clock.tick(10000);
                });

                it("calls save", function() {
                    expect(this.view.model.save).toHaveBeenCalled();
                });

                it("saves the selected content only", function() {
                    expect(this.view.model.content()).toBe('big');
                });

                it("puts the cursor at the end of the file", function() {
                    expect(this.view.editor.getCursor().ch).toBe("big".length);
                });

                it("sets readonly to nocursor", function() {
                    expect(this.view.editor.getOption("readOnly")).toBe(false);
                });

                it("maintains the editor in edit mode", function() {
                    expect(this.view.$(".CodeMirror")).toHaveClass("cm-s-editable");
                });

                context("when there is a version conflict", function() {
                    it("shows the version conflict alert", function() {
                        this.server.lastUpdate().failUnprocessableEntity({fields: {version: {INVALID: {}}}});

                        expect(this.modalSpy).toHaveModal(chorus.alerts.WorkfileConflict);
                    });
                });
            });

            describe("event file:createNewVersionFromSelection", function() {
                beforeEach(function() {
                    chorus.PageEvents.trigger("file:createNewVersionFromSelection");
                });

                it("calls stops the auto save timer", function() {
                    expect(this.view.stopTimer).toHaveBeenCalled();
                });

                it("updates the model", function() {
                    expect(this.view.model.content()).toBe("big");
                });

                it("puts the cursor at the end of the file", function() {
                    expect(this.view.editor.getCursor().ch).toBeGreaterThan("big".length - 1);
                });

                it("launches save workfile as new version dialog", function() {
                    expect(this.modalSpy).toHaveModal(chorus.dialogs.WorkfileNewVersion);
                });

                it("launches the new dialog with the correct model", function() {
                    expect(this.view.dialog.model).toBeA(chorus.models.Workfile);
                });
            });

            describe("event file:editorSelectionStatus", function() {
                beforeEach(function() {
                    spyOn(chorus.PageEvents, "trigger").andCallThrough();
                });

                it("calls file:selectionPresent when there is some text selected", function() {
                    this.view.editor.setSelection({line: 0, ch: 17}, {line: 0, ch: 20});

                    chorus.PageEvents.trigger("file:editorSelectionStatus");

                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("file:selectionPresent");
                });

                it("calls file:selectionEmpty when there is No text selected", function() {
                    this.view.editor.setSelection({line: 0, ch: 17}, {line: 0, ch: 17});

                    chorus.PageEvents.trigger("file:editorSelectionStatus");

                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("file:selectionEmpty");
                });
            });
        });
    });

    describe("when navigating away", function() {
        beforeEach(function() {
            this.view.render();
        });

        context("when the file has been changed", function() {
            beforeEach(function() {
                this.view.editor.setValue("Foo, Bar, Baz, Quux");
                chorus._navigated();
            });

            it("saves a draft", function() {
                expect(this.server.lastCreate().json()['workfile_draft']['content']).toEqual("Foo, Bar, Baz, Quux");
            });
        });

        context("when the file has not been changed", function() {
            beforeEach(function() {
                chorus._navigated();
            });

            it("does not save the draft", function() {
                expect(this.server.creates().length).toBe(0);
            });
        });
    });

    describe("when the user changes the selection", function() {
        beforeEach(function() {
            spyOn(chorus.PageEvents, "trigger");
            this.view.render();
            this.view.editor.setValue("content\n\nmore content");
        });

        context("the selection range is empty", function() {
            it("fires the selection empty event", function() {
                this.view.editor.setSelection({line: 1, ch: 0}, {line: 1, ch: 0});
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith('file:selectionEmpty');
            });
        });

        context("the selection range is not empty", function() {
            it("fires the selection present event", function() {
                this.view.editor.setSelection({line: 0, ch: 0}, {line: 2, ch: 0});
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith('file:selectionPresent');
            });
        });
    });
});
