describe("chorus.dialogs.HdfsImportConflict", function() {
    beforeEach(function () {
        this.upload = backboneFixtures.upload();
        this.hdfsEntry = backboneFixtures.hdfsDir();
        this.hdfsDataSource = this.hdfsEntry.getHdfsDataSource();

        this.hdfsImport = new chorus.models.HdfsImport({
            uploadId: this.upload.id,
            hdfsEntryId: this.hdfsEntry.id,
            hdfsDataSourceId: this.hdfsDataSource.id,
            fileName: "conflicted.csv"
        });

        this.hdfsImport.serverErrors = { fields: { file_name: { TAKEN: {} } } };

        this.modalSpy = stubModals();

        this.dialog = new chorus.dialogs.HdfsImportConflict({ model: this.hdfsImport });
        this.dialog.launchModal();
    });

    it("has the correct title", function () {
        expect(this.dialog.$(".dialog_header h1").text()).toMatchTranslation("hdfs.import.dialog.title");
    });

    it("has an 'Import' button", function() {
        expect(this.dialog.$("button.submit").text()).toMatchTranslation("hdfs.import.create");
    });

    it("renders the models errors", function () {
        expect(this.dialog.$(".errors ul")).toContainTranslation("field_error.TAKEN", {field: "File name"});
    });

    it("pre-populates the input with the invalid file name", function () {
        expect(this.dialog.$("input.file_name").val()).toBe("conflicted.csv");
    });

    context("changing the filename", function () {
        beforeEach(function () {
            this.dialog.$("input.file_name").val("unique_name.csv");
        });

        context("creating the import", function () {
            beforeEach(function () {
                this.dialog.$("form").submit();
            });

            it("should display a loading spinner", function() {
                expect(this.dialog.$("button.submit").text()).toMatchTranslation("actions.creating");
                expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
            });

            it("creates an hdfs import", function () {
                var url = '/hdfs_data_sources/' + this.hdfsDataSource.id + '/files/' + this.hdfsEntry.id + '/imports';
                expect(this.server.lastCreate().url).toBe(url);
                var json = this.server.lastCreate().json();
                expect(json['hdfs_import']['upload_id']).toBe(this.upload.id);
                expect(json['hdfs_import']['file_name']).toBe("unique_name.csv");
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
                    this.server.lastCreate().failUnprocessableEntity({ fields: { something: { TAKEN: {} } } });
                });

                it("stops loading and displays server errors", function () {
                    expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
                    expect(this.dialog.$(".errors ul")).toContainTranslation("field_error.TAKEN", {field: "Something"});
                });

                it("disables the submit button", function () {
                    expect(this.dialog.$("button.submit")).toBeDisabled();
                });
            });
        });
    });

    context("clicking cancel", function () {
        beforeEach(function () {
            spyOn(this.dialog, "closeModal");
            this.dialog.render();
            this.dialog.$("button.cancel").click();
        });

        it("closes the dialog", function () {
            expect(this.dialog.closeModal).toHaveBeenCalled();
        });
    });
});
