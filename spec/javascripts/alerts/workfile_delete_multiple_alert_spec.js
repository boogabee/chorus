describe("chorus.alerts.WorkfileDeleteMultiple", function() {
    beforeEach(function() {
        this.workspace = new chorus.models.Workspace({id: 1234});
        this.collection = new chorus.collections.WorkfileSet([
            backboneFixtures.workfile.sql({workspace: {id: this.workspace.id}}),
            backboneFixtures.workfile.sql({workspace: {id: this.workspace.id}})],
            {workspaceId: this.workspace.id}
        );
        this.alert = new chorus.alerts.WorkfileDeleteMultiple({ collection : this.collection });
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

    describe("when the workfile deletion is successful", function() {
        beforeEach(function() {
            spyOn(chorus.router, "navigate");
            spyOn(chorus, 'toast');
            this.alert.$("button.submit").click();
            this.server.lastDestroyFor(this.collection).succeed();
        });

        it("displays a toast message", function() {
            expect(chorus.toast).toHaveBeenCalledWith("workfile.delete.many.toast", {count: this.collection.length});
        });

        it("navigates to the workfile list page", function() {
            expect(chorus.router.navigate).toHaveBeenCalledWith("#/workspaces/" + this.collection.attributes.workspaceId + "/workfiles");
        });
    });
});
