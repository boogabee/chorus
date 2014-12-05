describe("chorus.dialogs.WorkfilesImport", function() {
    beforeEach(function() {
        chorus.models.Config.instance().set({fileSizesMbWorkfiles: 10});
        this.workspace = backboneFixtures.workspace();
        this.dialog = new chorus.dialogs.WorkfilesImport({pageModel: this.workspace});
        spyOn(this.dialog, 'centerHorizontally');
    });

    it("does not re-render when the model changes", function() {
        expect(this.dialog.persistent).toBeTruthy();
    });

    describe("#render", function() {
        beforeEach(function() {
            spyOn(this.dialog, "closeModal");
            this.dialog.render();
        });

        it("has the right action url", function() {
            expect(this.dialog.$("form").attr("action")).toBe("/workspaces/" + this.workspace.id + "/workfiles");
        });

        it("disables the upload button", function() {
            expect(this.dialog.$("button.submit")).toBeDisabled();
        });

        context("clicking on the cancel button", function() {
            it("closes the dialog", function() {
                this.dialog.$("button.cancel").click();
                expect(this.dialog.closeModal).toHaveBeenCalled();
            });
        });

        it("does not have the 'chosen' class on the form", function() {
            expect(this.dialog.$("form")).not.toHaveClass("chosen");
        });

        it("shows no file selected text", function() {
            expect(this.dialog.$(".file .empty_selection")).not.toHaveClass("hidden");
        });
    });

    describe("when the upload completes", function() {
        beforeEach(function() {
            spyOn(chorus.router, "navigate");
            this.fakeUpload = stubFileUpload();

            this.dialog.render();

            this.fakeUpload.add([ "foo.txt "]);
            this.fakeUpload.succeed({
                response: {
                    id: "9",
                    file_name: "new_file.txt",
                    mime_type: "text/plain",
                    workspace: { id: this.workspace.id.toString() }
                }
            });
        });

        it("navigates to the show page of the workfile", function() {
            expect(chorus.router.navigate).toHaveBeenCalledWith("#/workspaces/" + this.workspace.id + "/workfiles/9");
        });

        it ("enables the choosefile button again", function() {
            expect(this.dialog.$("button.choose").prop("disabled")).toBeFalsy();
            expect(this.dialog.$("input[type=file]")).not.toHaveClass("hidden");
        });
    });

    context("when clicking the 'upload a file' button", function() {
        beforeEach(function() {
            spyOn(this.dialog, 'chooseFile').andCallThrough();
            this.dialog.render();

            // Avoid changing the page if the test fails
            this.dialog.$('form').submit(function(e) {
                e.preventDefault();
            });
        });

        it("calls the chooseFile method (to support FF13, which doesn't receive a click on the 'input' field)", function() {
            this.dialog.$('button.choose').click();
            expect(this.dialog.chooseFile).toHaveBeenCalled();
        });
    });

    context("when a non-Alpine file has been chosen", function() {
        beforeEach(function() {
            this.fakeUpload = stubFileUpload();
            spyOn(this.dialog, "closeModal").andCallThrough();

            this.dialog.render();

            this.fakeUpload.add([ "foo.bar" ]);
        });

        it("enables the upload button", function() {
            expect(this.dialog.$("button.submit")).not.toBeDisabled();
        });

        it("does not put the button in loading mode", function() {
            expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
        });

        it("displays the chosen filename", function() {
            expect(this.dialog.$(".file_name").text()).toBe("foo.bar");
        });

        it("displays the appropriate file icon", function() {
            expect(this.dialog.$("img").attr("src")).toBe(chorus.urlHelpers.fileIconUrl("bar", "icon"));
        });

        it("makes the comment field visible", function() {
            expect(this.dialog.$(".comment")).not.toHaveClass("hidden");
        });

        it("hides the 'no file selected' text", function() {
            expect(this.dialog.$(".file .empty_selection")).toHaveClass("hidden");
        });

        describe("validating file size", function(){
            context("when it exceeds the maximum file size", function() {
                beforeEach(function() {
                    this.fakeUpload.add([{ name: "foo.bar", size: 99999999999999 }]);
                });

                it("shows an error", function() {
                    expect(this.dialog.$(".errors")).toContainText("file exceeds");
                });

                it("disables the upload button", function() {
                    expect(this.dialog.$("button.submit")).toHaveAttr("disabled");
                    expect(this.dialog.$("button.choose").prop("disabled")).toBeFalsy();
                    expect(this.dialog.$("input[type=file]")).not.toHaveClass("Hidden");
                });

                describe("when the user tries again with a smaller file", function() {
                    it("doesn't show an error", function() {
                        this.fakeUpload.add([{ name: "foo.bar", size: 10 * 1024 * 1024 -1 }]);
                        expect(this.dialog.$(".errors")).not.toContainText("file exceeds");
                        expect(this.dialog.$("button.submit").prop("disabled")).toBeFalsy();
                        expect(this.dialog.$("button.choose").prop("disabled")).toBeFalsy();
                        expect(this.dialog.$("input[type=file]")).not.toHaveClass("Hidden");
                    });
                });
            });

            context("when the upload gives a server error", function() {
                beforeEach(function() {
                    this.fileList = [{ name: 'foo Bar Baz.csv', size: 1 }];
                    this.fakeUpload.add(this.fileList);
                    var errors = { errors: { fields: { contents_file_size: { LESS_THAN: { message: "file_size_exceeded", count: "5242880 Bytes"}}}}};
                    this.fakeUpload.HTTPResponseFail(JSON.stringify(errors), 422, "Unprocessable Entity", {noResult: true});
                });

                it("sets the server errors on the model", function() {
                    expect(this.dialog.$('.errors')).toContainText("Contents file size must be less than 5 MB");
                });
            });

            context("when it is within the limit", function() {
                it("doesn't show an error", function() {
                    this.fakeUpload.add([{ name: "foo.bar", size: 10 * 1024 * 1024 -1 }]);
                    expect(this.dialog.$(".errors")).not.toContainText("file exceeds");
                });
            });

            context("when nginx returns a 413 (body too large) error", function() {
                it("shows the file too large error message", function() {
                    this.fakeUpload.add([{ name: "invalid.bar", size: 10 * 1024 * 1024 - 1 }]);
                    var html_response = '<html>\n<head><title>413 Request Entity Too Large</title></head>\n<body bgcolor="white">\n<center><h1>413 Request Entity Too Large</h1></center> <hr><center>nginx/1.2.2</center>\n </body>\n </html>\n <!-- a padding to disable MSIE and Chrome friendly error page -->\n <!-- a padding to disable MSIE and Chrome friendly error page -->\n <!-- a padding to disable MSIE and Chrome friendly error page -->\n <!-- a padding to disable MSIE and Chrome friendly error page -->\n <!-- a padding to disable MSIE and Chrome friendly error page -->\n <!-- a padding to disable MSIE and Chrome friendly error page -->\n';
                    this.fakeUpload.HTTPResponseFail(html_response, 413, "Request Entity Too Large", {});
                    expect(this.dialog.$(".errors")).toContainText("file exceeds");
                    expect(this.dialog.$("button.submit").prop("disabled")).toBeTruthy();
                    expect(this.dialog.$("button.choose").prop("disabled")).toBeFalsy();
                    expect(this.dialog.$("input[type=file]")).not.toHaveClass("Hidden");
                });
            });
        });

        context("#upload", function() {
            beforeEach(function() {
                this.dialog.upload();
            });

            it("uploads the specified file", function() {
                expect(this.fakeUpload.wasSubmitted).toBeTruthy();
            });

            it("puts the upload button in the loading state", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
            });

            it("disables the upload button and select file also", function() {
                expect(this.dialog.$("button.submit").prop("disabled")).toBeTruthy();
                expect(this.dialog.$("button.choose").prop("disabled")).toBeTruthy();
                expect(this.dialog.$("input")).toBeHidden();
            });

            it("changes the text on the upload button to 'uploading'", function() {
                expect(this.dialog.$("button.submit").text()).toBe(t("workfiles.import_dialog.uploading"));
            });

            context("when cancel is clicked before the upload completes", function() {
                beforeEach(function() {
                    this.dialog.$("button.cancel").click();
                });

                it("closes the dialog", function() {
                    expect(this.dialog.closeModal).toHaveBeenCalled();
                });

                it("cancels the upload", function() {
                    expect(this.fakeUpload.wasAborted).toBeTruthy();
                });
            });

            context("when the close 'X' is clicked", function() {
                beforeEach(function() {
                    $(document).trigger("close.facebox");
                });

                it("cancels the upload", function() {
                    expect(this.fakeUpload.wasAborted).toBeTruthy();
                });
            });

            context("when the upload gives a server error", function() {
                beforeEach(function() {
                    this.saveFailedSpy = jasmine.createSpy();
                    this.dialog.resource.bind("saveFailed", this.saveFailedSpy);
                    this.fakeUpload.fail({ errors : { fields: { a: { BLANK: {} } } }});
                });

                it("triggers saveFailed on the model", function() {
                    expect(this.saveFailedSpy).toHaveBeenCalled();
                });

                it("disables the upload button", function() {
                    expect(this.dialog.$("button.submit").prop("disabled")).toBeTruthy();
                    expect(this.dialog.$("button.choose").prop("disabled")).toBeFalsy();
                    expect(this.dialog.$("input[type=file]")).not.toHaveClass("Hidden");
                });

                it("takes the upload button out of the loading state", function() {
                    expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
                });

                it("displays the correct error", function() {
                    expect(this.dialog.$(".errors ul").text()).toBe("A can't be blank");
                });

                it("sets the button text back to 'Upload File'", function() {
                    expect(this.dialog.$("button.submit").text()).toMatchTranslation("workfiles.button.import");
                });

                it ("enables the choosefile button again", function() {
                    expect(this.dialog.$("button.choose").prop("disabled")).toBeFalsy();
                });
            });
        });

        context("when the Enter key is pressed", function() {
            beforeEach(function() {
                this.dialog.$("form").submit();
            });

            it("uploads the specified file", function() {
                expect(this.fakeUpload.wasSubmitted).toBeTruthy();
            });
        });

        context("when the upload button is clicked", function() {
            beforeEach(function() {
                this.dialog.$("button.submit").click();
            });

            it("uploads the specified file", function() {
                expect(this.fakeUpload.wasSubmitted).toBeTruthy();
            });
        });

        it("shrinks and centers the modal", function () {
            expect(this.dialog.centerHorizontally).toHaveBeenCalled();
            expect(this.dialog.$el).not.toHaveClass('dialog_wide');
        });
    });

    context("when a .afm file has been chosen", function () {
        beforeEach(function () {
            this.fakeUpload = stubFileUpload();
            this.dialog.render();
            this.fakeUpload.add([ "foo.afm" ]);
        });

        it("shows an execution_location_picker_list", function () {
            expect(this.dialog.$(".execution_location_picker_list")).toExist();
        });

        it("should only enable the submit button when the execution location picker is ready", function () {
            this.dialog.executionLocationPickerList.trigger('change');
            expect(this.dialog.$("button.submit")).toBeDisabled();

            spyOn(this.dialog.executionLocationPickerList, 'ready').andReturn(true);

            this.dialog.executionLocationPickerList.trigger('change');
            expect(this.dialog.$("button.submit")).toBeEnabled();
        });

        it("sets entitySubtype to 'alpine'", function () {
            expect(this.dialog.$('input#entity_subtype')).toHaveValue('alpine');
        });

        describe("changing the execution location", function() {
            beforeEach(function () {
                this.hdfs = backboneFixtures.hdfsDataSource();

                var hdfsDataSources = this.dialog.executionLocationPickerList.pickers[0].dataSourceView.hdfsDataSources;
                this.server.completeFetchAllFor(hdfsDataSources, [this.hdfs]);

                var dataSources = this.dialog.executionLocationPickerList.pickers[0].dataSourceView.databaseDataSources;
                this.server.completeFetchAllFor(dataSources, []);
            });

            it("sets values on the form", function () {
                expect(this.dialog.$('form .execution_locations input').length).toEqual(0);

                this.dialog.$(".data_source select").prop("selectedIndex", 1).change();

                var execution_location_fields = {};
                _.each(this.dialog.$('form .execution_locations input'), function (field) {
                    execution_location_fields[$(field).attr('name')] = $(field).attr('value');
                });

                expect(execution_location_fields['workfile[execution_locations][0][entity_type]']).toEqual('hdfs_data_source');
                expect(execution_location_fields['workfile[execution_locations][0][id]']).toEqual(this.hdfs.id);
            });
        });

        describe("uploading", function() {
            describe("when the work flow is not created due to an alpine connection error", function() {
                beforeEach(function() {
                    this.dialog.model.serverErrors = { fields: { base: { ALPINE_CONNECTION_ERROR: {} } } };
                    this.dialog.resource.trigger('saveFailed');
                });

                it("should display the correct error message", function() {
                    expect(this.dialog.$(".errors")).toContainTranslation("field_error.ALPINE_CONNECTION_ERROR");
                });
            });
        });

        it("widens and centers the modal", function () {
            expect(this.dialog.centerHorizontally).toHaveBeenCalled();
            expect(this.dialog.$el).toHaveClass('dialog_wide');
        });
    });
});
