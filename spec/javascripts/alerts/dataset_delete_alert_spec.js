describe("chorus.alerts.DatasetDelete", function() {
    beforeEach(function() {
        this.model = backboneFixtures.workspaceDataset.chorusView();
        this.alert = new chorus.alerts.DatasetDelete({ keyPrefix: 'chorus_view', pageModel : this.model });
        stubModals();
        this.alert.launchModal();
    });

    it("does not re-render when the model changes", function() {
        expect(this.alert.persistent).toBeTruthy();
    });

    it("has the correct title and text for each type", function () {
        var tableAlert = new chorus.alerts.DatasetDelete({ keyPrefix: 'table', pageModel : this.model });
        expect(tableAlert.title).toMatchTranslation("dataset_delete.table.title");
        expect(tableAlert.text).toMatchTranslation("dataset_delete.table.text");

        var viewAlert = new chorus.alerts.DatasetDelete({ keyPrefix: 'view', pageModel : this.model });
        expect(viewAlert.title).toMatchTranslation("dataset_delete.view.title");
        expect(viewAlert.text).toMatchTranslation("dataset_delete.view.text");

        var chorusViewAlert = new chorus.alerts.DatasetDelete({ keyPrefix: 'chorus_view', pageModel : this.model });
        expect(chorusViewAlert.title).toMatchTranslation("dataset_delete.chorus_view.title");
        expect(chorusViewAlert.text).toMatchTranslation("dataset_delete.chorus_view.text");

        var hdfsDatasetAlert = new chorus.alerts.DatasetDelete({ keyPrefix: 'hdfs_dataset', pageModel : this.model });
        expect(hdfsDatasetAlert.title).toMatchTranslation("dataset_delete.hdfs_dataset.title");
        expect(hdfsDatasetAlert.text).toMatchTranslation("dataset_delete.hdfs_dataset.text");
    });

    it("has the correct title", function() {
        expect(this.alert.title).toBe(t("dataset_delete.chorus_view.title", this.model.name()));
    });

    it("has the correct text", function() {
        expect(this.alert.text).toBe(t("dataset_delete.chorus_view.text"));
    });

    describe("when the alert closes", function() {
        beforeEach(function() {
            this.alert.render();
            this.alert.$("button.cancel").click();
            spyOn(chorus.router, "navigate");
            spyOn(chorus, 'toast');
        });

        it("unbinds event handlers on the model", function() {
            this.model.trigger("destroy");
            expect(chorus.toast).not.toHaveBeenCalled();
            expect(chorus.router.navigate).not.toHaveBeenCalled();
        });
    });

    describe("when the dataset deletion is successful", function() {
        beforeEach(function() {
            spyOn(chorus.router, "navigate");
            spyOn(chorus, 'toast');
            this.name = this.model.name();
            this.alert.model.destroy();
            this.server.lastDestroy().succeed();
        });

        it("displays a toast message", function() {
            expect(chorus.toast).toHaveBeenCalledWith("dataset_delete.chorus_view.toast", {datasetName: this.name});
        });

        it("navigates to the dataset list page", function() {
            expect(chorus.router.navigate).toHaveBeenCalledWith("#/workspaces/" + this.alert.model.get('workspace').id + "/datasets");
        });
    });
});
