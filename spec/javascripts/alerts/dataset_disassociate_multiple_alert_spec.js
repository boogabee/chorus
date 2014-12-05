describe("chorus.alerts.DatasetDisassociateMultiple", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.WorkspaceDatasetSet([
            backboneFixtures.workspaceDataset.datasetTable({id: 0}),
            backboneFixtures.workspaceDataset.datasetTable({id: 1}),
            backboneFixtures.workspaceDataset.datasetTable({id: 3})
        ], {workspaceId: 1234});

        this.alert = new chorus.alerts.DatasetDisassociateMultiple({ collection : this.collection });
        stubModals();
        this.alert.launchModal();
    });

    describe("when the alert closes", function() {
        beforeEach(function() {
            this.alert.render();
            this.alert.$("button.cancel").click();
            spyOn(chorus.router, "navigate");
            spyOn(chorus, 'toast');
        });

        it("unbinds event handlers on the model", function() {
            this.collection.trigger("destroy");
            expect(chorus.toast).not.toHaveBeenCalled();
            expect(chorus.router.navigate).not.toHaveBeenCalled();
        });
    });

    describe("when the dataset deletion is successful", function() {
        beforeEach(function() {
            spyOn(chorus.router, "navigate");
            spyOn(chorus, 'toast');
            this.alert.$("button.submit").click();
            this.server.lastDestroy().succeed();
        });

        it("displays a toast message", function() {
            expect(chorus.toast).toHaveBeenCalledWith("dataset_delete.many.toast", {count: this.collection.length});
        });

        it("navigates to the dataset list page", function() {
            expect(chorus.router.navigate).toHaveBeenCalledWith("#/workspaces/" + this.collection.attributes.workspaceId + "/datasets");
        });
    });
});
