describe("chorus.dialogs.HdfsImportDialog", function () {
    beforeEach(function () {
        chorus.models.Config.instance().set({fileSizesMbHdUpload: 1 });
        chorus.page = {};

        this.modalSpy = stubModals();
        this.fakeFileUpload = stubFileUpload();

        this.entry = backboneFixtures.hdfsDir();
        this.hdfsDataSource = this.entry.getHdfsDataSource();
        this.dialog = new chorus.dialogs.HdfsImportDialog({
            pageModel: this.entry
        });
        this.dialog.launchModal();
    });

    it("has the right title", function() {
        expect(this.dialog.$(".dialog_header h1").text()).toMatchTranslation("hdfs.import.dialog.title");
    });

    it("has a 'Cancel' button", function() {
        expect(this.dialog.$("button.cancel").text()).toMatchTranslation("actions.cancel");
    });

    it("has an 'Import' button", function() {
        expect(this.dialog.$("button.submit").text()).toMatchTranslation("hdfs.import.create");
    });

    it("has a file picker", function() {
        expect(this.dialog.$("input[type=file]")).toExist();
        expect(this.dialog.$(".file-wrapper button")).not.toHaveClass("hidden");
        expect(this.dialog.$(".file-wrapper button").text()).toMatchTranslation("dataset.import.select_file");
    });

    it("has a 'Change' link", function() {
        expect(this.dialog.$(".file-wrapper a").text()).toMatchTranslation("actions.change");
    });

    it("displays 'No File Chosen' by default", function() {
        expect(this.dialog.$(".empty_selection").text()).toMatchTranslation("dataset.import.no_file_selected");
    });

    it("hides the file type img by default", function() {
        expect(this.dialog.$(".upload_widget img")).toHaveClass("hidden");
    });

    it("hides the 'Change' link by default", function() {
        expect(this.dialog.$(".file-wrapper a")).toHaveClass("hidden");
    });

    context("when a file is chosen", function() {
        beforeEach(function () {
            this.fileList = [{ name: 'foo Bar Baz.csv' }];
            this.fakeFileUpload.add(this.fileList);
        });

        describe("default settings", function() {
            it("enables the upload button", function() {
                expect(this.dialog.$("button.submit")).toBeEnabled();
            });

            it("displays the chosen filename", function() {
                expect(this.dialog.$(".file_name").text()).toBe("foo Bar Baz.csv");
            });

            it("displays the appropriate file icon", function() {
                expect(this.dialog.$(".upload_widget img")).not.toHaveClass("hidden");
                expect(this.dialog.$(".upload_widget img").attr("src")).toBe(chorus.urlHelpers.fileIconUrl("csv", "icon"));
            });

            it("should hide the 'No file Selected' text", function() {
                expect(this.dialog.$(".empty_selection")).toHaveClass("hidden");
            });

            it("shows the 'Change' link", function() {
                expect(this.dialog.$(".file-wrapper a")).not.toHaveClass("hidden");
            });
        });

        describe("file size validation", function() {
            describe("when the file size is within limits", function() {
                beforeEach(function() {
                    this.fileList = [{ name: 'foo Bar Baz.csv', size: 1 * 1024 * 1024 - 1 }];
                    this.fakeFileUpload.add(this.fileList);
                });

                it("does not show a file size error", function() {
                    this.dialog.validateFileSize();
                    expect(this.dialog.$('.errors')).not.toContainText("file exceeds");
                });
            });

            describe("when the file size exceeds the maximum allowed size", function() {
                beforeEach(function() {
                    this.fileList = [{ name: 'foo Bar Baz.csv', size: 999999999999999999 }];
                    this.fakeFileUpload.add(this.fileList);
                });

                it("shows an error", function() {
                    this.dialog.validateFileSize();
                    expect(this.dialog.$('.errors')).toContainText("file exceeds");
                    expect(this.dialog.$('button.submit')).not.toBeEnabled();
                });

                it("removes the error when a valid file is then selected", function() {
                    this.fileList = [{ name: 'foo Bar Baz.csv', size: 1 * 1024 * 1024 - 1 }];
                    this.fakeFileUpload.add(this.fileList);
                    this.dialog.validateFileSize();
                    expect(this.dialog.$('.errors')).not.toContainText("file exceeds");
                    expect(this.dialog.$('button.submit')).toBeEnabled();
                });
            });

            context("when the upload gives a server error", function() {
                beforeEach(function() {
                    this.fileList = [{ name: 'foo Bar Baz.csv', size: 1 }];
                    this.fakeFileUpload.add(this.fileList);
                    var errors = { errors: { fields: { contents_file_size: { LESS_THAN: { message: "file_size_exceeded", count: "5242880 Bytes"}}}}};
                    this.fakeFileUpload.HTTPResponseFail(JSON.stringify(errors), 422, "Unprocessable Entity", {noResult: true});
                });

                it("sets the server errors on the model", function() {
                    expect(this.dialog.$('.errors')).toContainText("Contents file size must be less than 5 MB");
                });
            });

            describe("when nginx returns a 413 (body too large) error", function() {
                it("shows that error", function() {
                    this.fileList = [{ name: 'finefile.bar', size: 1 * 1024 * 1024 - 1 }];
                    var html_response = '<html>\n<head><title>413 Request Entity Too Large</title></head>\n<body bgcolor="white">\n<center><h1>413 Request Entity Too Large</h1></center> <hr><center>nginx/1.2.2</center>\n </body>\n </html>\n <!-- a padding to disable MSIE and Chrome friendly error page -->\n <!-- a padding to disable MSIE and Chrome friendly error page -->\n <!-- a padding to disable MSIE and Chrome friendly error page -->\n <!-- a padding to disable MSIE and Chrome friendly error page -->\n <!-- a padding to disable MSIE and Chrome friendly error page -->\n <!-- a padding to disable MSIE and Chrome friendly error page -->\n';

                    this.fakeFileUpload.HTTPResponseFail(html_response, 413, "Request Entity Too Large", {noResult: true});
                    expect(this.dialog.$(".errors")).toContainText("413: Request Entity Too Large");
                });
            });
        });

        describe("clicking Upload", function() {
            beforeEach(function () {
                this.dialog.$("button.submit").click();
            });

            it("should display a loading spinner", function() {
                expect(this.dialog.$("button.submit").text()).toMatchTranslation("actions.uploading");
                expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
                expect(this.dialog.$("button.choose")).toBeDisabled();
            });

            it("uploads the specified file", function() {
                expect(this.dialog.uploadObj.url).toEqual("/uploads");
                expect(this.fakeFileUpload.wasSubmitted).toBeTruthy();
            });

            it("Should disable the change file link", function() {
                expect(this.dialog.$(".file-wrapper a")).toHaveClass("hidden");
            });

            context("when upload succeeds", function() {
                beforeEach(function () {
                    this.upload = backboneFixtures.upload();
                    this.data = {
                        result: {
                            response: this.upload.attributes,
                            status: "ok"
                        }
                    };
                    this.fakeFileUpload.done(null, this.data);
                    this.fakeFileUpload.always();
                });

                describe("creating the hdfs import", function () {
                    it("creates an hdfs import", function () {
                        var url = '/hdfs_data_sources/' + this.hdfsDataSource.id + '/files/' + this.entry.id + '/imports';
                        expect(this.server.lastCreate().url).toBe(url);
                        var json = this.server.lastCreate().json();
                        expect(json['hdfs_import']['upload_id']).toBe(this.upload.id);
                    });

                    context("when the create is successful", function () {
                        beforeEach(function () {
                            spyOn(this.dialog, "closeModal");
                            spyOn(chorus, 'toast');

                            this.server.lastCreate().succeed();
                        });

                        it("closes the dialog and displays a toast", function () {
                            expect(this.dialog.closeModal).toHaveBeenCalled();
                            expect(chorus.toast).toHaveBeenCalledWith("hdfs.import.started");
                        });
                    });

                    context("when the save fails", function () {
                        beforeEach(function () {
                            this.modalSpy.reset();
                            spyOn(this.dialog, "closeModal");
                            this.server.lastCreate().failUnprocessableEntity();
                        });

                        it("closes the upload dialog and launches the HdfsImport conflict dialog", function () {
                            expect(this.dialog.closeModal).toHaveBeenCalled();
                            expect(this.modalSpy).toHaveModal(chorus.dialogs.HdfsImportConflict);
                            expect(this.modalSpy.modals().length).toBe(1);
                        });

                        it("sets the fileName on the hdfs import", function () {
                            var hdfsImport = this.modalSpy.lastModal().model;
                            expect(hdfsImport.get("fileName")).toBeDefined();
                        });
                    });
                });
            });
        });
    });
});
