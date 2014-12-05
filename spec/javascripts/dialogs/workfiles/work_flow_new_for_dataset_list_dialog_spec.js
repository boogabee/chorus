describe("chorus.dialogs.WorkFlowNewForDatasetList", function() {
    beforeEach(function() {
        var dataset1 = backboneFixtures.dataset({id: 1});
        var dataset2 = backboneFixtures.dataset({id: 2});
        this.workspace = backboneFixtures.workspace();
        this.dialog = new chorus.dialogs.WorkFlowNewForDatasetList({
            pageModel: this.workspace,
            collection: new chorus.collections.Base([dataset1, dataset2])
        });
        this.dialog.render();
    });

    it("has the right title", function() {
        expect(this.dialog.$(".dialog_header h1")).toContainTranslation("work_flows.new_dialog.title");
    });

    it("has an Add Work Flow button", function() {
        expect(this.dialog.$("button.submit")).toContainTranslation("work_flows.new_dialog.add_work_flow");
    });

    describe("submitting", function() {
        beforeEach(function() {
            // start with a valid form submission
            this.dialog.$("input[name='fileName']").val("stuff").keyup();
        });

        describe("with valid form values", function() {
            it("enables the submit button", function() {
                expect(this.dialog.$("form button.submit")).not.toBeDisabled();
            });

            it("submits the form", function() {
                this.dialog.$("form").submit();
                expect(this.server.lastCreate().json()["workfile"]["entity_subtype"]).toEqual('alpine');
                expect(this.server.lastCreate().json()["workfile"]["dataset_ids"]).toEqual([1, 2]);
            });
        });

        describe("when the workfile creation succeeds", function() {
            beforeEach(function() {
                spyOn(this.dialog, "closeModal");
                spyOn(chorus.router, "navigate");
                this.dialog.$("form").submit();
                this.server.completeCreateFor(this.dialog.resource, {id: 42});
            });

            it("closes the dialog", function() {
                expect(this.dialog.closeModal).toHaveBeenCalled();
            });

            it("navigates to the workflow page", function() {
                expect(chorus.router.navigate).toHaveBeenCalledWith("#/work_flows/42");
            });
        });

        describe("when the save fails", function() {
            beforeEach(function() {
                spyOn($.fn, 'stopLoading');
                this.dialog.model.trigger("saveFailed");
            });

            it("removes the spinner from the button", function() {
                expect($.fn.stopLoading).toHaveBeenCalledOnSelector("button.submit");
            });
        });

        describe("with an invalid work flow name", function() {
            it("does not allow submitting", function() {
                this.dialog.$("input[name='fileName']").val("     ").keyup();
                expect(this.dialog.$("form button.submit")).toBeDisabled();
            });
        });
    });
});