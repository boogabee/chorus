describe("chorus.dialogs.AssociateMultipleWithWorkspace", function() {
    beforeEach(function() {
        this.datasets = new chorus.collections.SchemaDatasetSet([
            backboneFixtures.dataset({ id: '123' }),
            backboneFixtures.dataset({ id: '456' }),
            backboneFixtures.dataset({ id: '789' })
        ]);

        this.dialog = new chorus.dialogs.AssociateMultipleWithWorkspace({
            collection: this.datasets
        });
        this.dialog.render();
    });

    it("has the right button text", function() {
        expect(this.dialog.submitButtonTranslationKey).toBe("dataset.associate.button.other");
    });

    describe("when the workspaces are fetched and one is chosen", function() {
        beforeEach(function() {
            this.server.completeFetchAllFor(chorus.session.user().workspaces(), [
                backboneFixtures.workspace({ name: "abra", id: "11" }),
                backboneFixtures.workspace({ name: "cadabra", id: "12" })
            ]);

            this.dialog.$("li:eq(1)").click();
            this.dialog.$("button.submit").click();
        });

        it("sends a request to the 'associate dataset' API", function() {
            expect(this.server.lastCreate().url).toContain("/workspaces/12/datasets");

        });

        it("sends all of the datasets' ids", function() {
            var json = this.server.lastCreate().json();
            expect(json['dataset_ids']).toEqual(['123', '456', '789']);
        });

        it("display loading message on the button", function() {
            expect(this.dialog.$("button.submit")).toHaveSpinner();
        });

        describe("when the request succeeds", function() {
            beforeEach(function() {
                spyOn(this.dialog, "closeModal");
                spyOn(chorus, "toast");
                this.server.lastCreate().succeed();
            });

            it("displays a toast message", function() {
                expect(chorus.toast).toHaveBeenCalledWith(
                    "dataset.associate.toast.other", { count: 3, workspaceNameTarget: "cadabra" }
                );
            });

            it("closes the dialog", function() {
                expect(this.dialog.closeModal).toHaveBeenCalled();
            });

            it("fetches the associated datasets", function() {
                this.dialog.datasets.each(function(dataset) {
                    expect(dataset).toHaveBeenFetched();
                });
            });
        });

        describe("when the request fails", function() {
            beforeEach(function() {
                this.server.lastCreate().failUnprocessableEntity({ fields: { a: { BLANK: {} } } });
            });

            it("displays the error message", function() {
                expect(this.dialog.$(".errors")).toContainTranslation("field_error.BLANK", {field: "A"});
            });

            it("stops the loading spinner", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
            });
        });
    });
});
