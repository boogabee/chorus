describe("chorus.dialogs.EditHdfsDataset", function() {
    beforeEach(function() {
        this.modalSpy = stubModals();
        this.dataset = backboneFixtures.workspaceDataset.hdfsDataset();
        this.dialog = new chorus.dialogs.EditHdfsDataset({model: this.dataset});
        this.dialog.launchModal();
    });

    it("shows the right title", function() {
        expect(this.dialog.title).toMatchTranslation("edit_hdfs_dataset.title");
    });

    it("prepopulates the dataset's name", function () {
        expect(this.dialog.$("input.name").val()).toEqual(this.dataset.get('objectName'));
    });

    it("prepopulates the dataset's file mask", function () {
        expect(this.dialog.$("input.file_mask").val()).toEqual(this.dataset.get('fileMask'));
    });

    it("has the save and cancel buttons", function() {
        expect(this.dialog.$("button.submit")).toContainTranslation("edit_hdfs_dataset.submit");
        expect(this.dialog.$("button.cancel")).toContainTranslation("actions.cancel");
    });

    context("when the form is filled in", function() {
        beforeEach(function() {
            this.dialog.$("input.name").val("Jim Carrey").change();
            this.dialog.$("input.file_mask").val("foo.*.bar").change().keyup();
        });

        it("enables the submit button", function() {
            expect(this.dialog.$("button.submit")).toBeEnabled();
        });

        context("submitting the form", function() {
            beforeEach(function() {
                this.dialog.$("form").submit();
            });

            it("posts with the correct values", function() {
                var json = this.server.lastUpdate().json()['hdfs_dataset'];
                expect(json['name']).toEqual("Jim Carrey");
                expect(json['dataset_id']).toEqual(this.dialog.model.id);
                expect(json['file_mask']).toEqual("foo.*.bar");
            });

            it("starts the spinner loading", function () {
                expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
            });

            it("adds the saving text to the submit button", function () {
                expect(this.dialog.$("button.submit")).toContainTranslation('actions.saving');
            });

            context("when the save succeeds", function () {
                beforeEach(function () {
                    spyOn(this.dialog, 'closeModal');
                    spyOn(chorus, 'toast');
                });

                it("closes the modal", function() {
                    this.server.completeUpdateFor(this.dialog.model);
                    expect(this.dialog.closeModal).toHaveBeenCalled();
                });

                it("gives a toast", function() {
                    this.server.completeUpdateFor(this.dialog.model);
                    expect(chorus.toast).toHaveBeenCalledWith('edit_hdfs_dataset.toast');
                });
            });

            context("when the post fails", function () {
                beforeEach(function() {
                    this.server.lastUpdateFor(this.dialog.model).failUnprocessableEntity();
                });

                it("displays server errors", function () {
                    expect(this.dialog.$('.errors')).not.toHaveClass('hidden');
                });

                it("stops the spinner", function() {
                    expect(this.dialog.$('button.submit').isLoading()).toBeFalsy();
                });
            });
        });
    });
});