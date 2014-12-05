describe("chorus.dialogs.AssociateWithWorkspace", function() {
    describe("after workspaces are fetched", function() {
        context("when the model is a source table/view with multiple workspaces", function() {
            beforeEach(function() {
                this.model = backboneFixtures.dataset({
                    associatedWorkspaces: [
                        {id: "123"},
                        {id: "645"}
                    ],
                    schema: { id: 2000002 }
                });
                this.dialog = new chorus.dialogs.AssociateWithWorkspace({ model: this.model });
                this.server.completeFetchFor(chorus.session.user().workspaces(), [
                    backboneFixtures.workspace({ name: "im_also_the_current_one'", id: "123" }),
                    backboneFixtures.workspace({ name: "im_not_the_current_one" }),
                    backboneFixtures.workspace({ name: "yes_im_the_current_one", id: "645" })
                ]);
            });

            it("shows all workspaces except for the ones the source table is already associated with", function() {
                expect(this.dialog.$("li").length).toBe(1);
                expect(this.dialog.$('li:eq(0) .name')).toContainText("im_not_the_current_one");
            });
        });

        context("when the model is a source table/view with no workspaces", function() {
            beforeEach(function() {
                this.model = backboneFixtures.workspaceDataset.datasetTable({
                    schema: { id: 2000002 }
                });
                this.model.unset("associatedWorkspaces");
                this.dialog = new chorus.dialogs.AssociateWithWorkspace({ model: this.model });
                this.server.completeFetchFor(chorus.session.user().workspaces(), [
                    backboneFixtures.workspace({ name: "im_not_the_current_one'" }),
                    backboneFixtures.workspace({ name: "me_neither" }),
                    backboneFixtures.workspace({ name: "yes_im_the_current_one", id: "645" })
                ]);
            });

            it("shows all workspaces", function() {
                expect(this.dialog.$("li").length).toBe(3);
                expect(this.dialog.$('li:eq(0) .name')).toContainText("im_not_the_current_one");
                expect(this.dialog.$('li:eq(1) .name')).toContainText("me_neither");
                expect(this.dialog.$('li:eq(2) .name')).toContainText("yes_im_the_current_one");
            });
        });

        context("when the model is a sandbox table/view or a chorus view (in a workspace)", function() {
            beforeEach(function() {
                this.model = backboneFixtures.workspaceDataset.datasetTable({
                    schema: { id: 2000002 },
                    workspace: {id: "645"}
                }
                );
                this.dialog = new chorus.dialogs.AssociateWithWorkspace({ model: this.model });
                this.server.completeFetchFor(chorus.session.user().workspaces(), [
                    backboneFixtures.workspace({ name: "im_not_the_current_one'" }),
                    backboneFixtures.workspace({ name: "me_neither" }),
                    backboneFixtures.workspace({ name: "yes_im_the_current_one", id: "645" })
                ]);
            });

            it("it shows all workspaces except for the current workspace", function() {
                expect(this.dialog.$("li").length).toBe(2);
                expect(this.dialog.$('li:eq(0) .name')).toContainText("im_not_the_current_one");
                expect(this.dialog.$('li:eq(1) .name')).toContainText("me_neither");
            });
        });

        context("when the model is a dataset found through the dataSource browser", function () {
            beforeEach(function() {
                this.model = backboneFixtures.dataset({
                    schema: { id: 2000002 }
                });
                this.dialog = new chorus.dialogs.AssociateWithWorkspace({ model: this.model });

                var targetWorkspace = backboneFixtures.workspace({
                    name: "my_sandbox_is_your_schema"
                });
                targetWorkspace.set('show_sandbox_datasets', true);
                targetWorkspace.set('sandbox_info', this.model.schema().attributes);

                this.server.completeFetchFor(chorus.session.user().workspaces(), [
                    backboneFixtures.workspace({ name: "im_not_your_schemas_workspace'" }),
                    backboneFixtures.workspace({ name: "me_neither" })
                ]);
            });

            it("it shows all workspaces except for those using the model's schema as their sandbox, and who show sandbox datasets", function() {
                expect(this.dialog.$("li").length).toBe(2);
                expect(this.dialog.$('li:eq(0) .name')).toContainText("im_not_your_schemas_workspace");
                expect(this.dialog.$('li:eq(1) .name')).toContainText("me_neither");
            });
        });
    });

    describe("clicking Associate Dataset", function() {
        context("for a dataset that is not a chorus_view", function() {
            beforeEach(function() {
                this.model = backboneFixtures.dataset({
                    schema: { id: 2000002 }
                });
                this.workspace = backboneFixtures.workspace({ name: "im_not_the_current_one" });

                this.dialog = new chorus.dialogs.AssociateWithWorkspace({ model: this.model });
                this.server.completeFetchFor(chorus.session.user().workspaces(), [
                    backboneFixtures.workspace({ name: "im_also_the_current_one'", id: "123" }),
                    this.workspace,
                    backboneFixtures.workspace({ name: "yes_im_the_current_one", id: "645" })
                ]);

                spyOn(chorus.router, "navigate");
                spyOn(chorus, "toast");
                spyOn(this.dialog, "closeModal");

                this.dialog.render();
                this.dialog.$('li:eq(1)').click();
                this.dialog.$("button.submit").click();
            });

            it("calls the API for associating new source tables with a workspace", function() {
                var uri = new URI(this.server.lastCreate().url);

                expect(uri.path()).toEqual("/workspaces/" + this.workspace.get("id") + "/datasets");
            });

            it("starts loading", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
                expect(this.dialog.$("button.submit").text()).toMatchTranslation("actions.associating");
            });

            describe("when the API is successful", function() {
                beforeEach(function() {
                    spyOn(chorus.PageEvents, "trigger");
                    this.server.lastCreate().succeed();
                });

                it("closes the dialog", function() {
                    expect(this.dialog.closeModal).toHaveBeenCalled();
                });

                it("pops toast", function() {
                    expect(chorus.toast).toHaveBeenCalledWith("dataset.associate.toast.one", {datasetTitle: this.model.get("objectName"), workspaceNameTarget: this.workspace.get("name")});
                });

                it("does not navigate", function() {
                    expect(chorus.router.navigate).not.toHaveBeenCalled();
                });

                it("fetches the activities for the dataset", function() {
                    expect(this.model.activities()).toHaveBeenFetched();
                });

                it("fetches the dataset", function() {
                    expect(this.dialog.model).toHaveBeenFetched();
                });
            });

            describe("when the API fails", function() {
                beforeEach(function() {
                    this.dialog.closeModal.reset();
                    this.server.lastRequest().failUnprocessableEntity({ fields: { a: { BLANK: {} } } });
                });

                it("does not close the dialog", function() {
                    expect(this.dialog.closeModal).not.toHaveBeenCalled();
                });

                it("does not pop toast", function() {
                    expect(chorus.toast).not.toHaveBeenCalled();
                });

                it("stops loading", function() {
                    expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
                });

                it("displays the server error message", function() {
                    expect(this.dialog.$(".errors ul").text().trim()).toBe("A can't be blank");
                });
            });
        });

        context("when the dataset is a Chorus View", function() {
            beforeEach(function() {
                this.currentWorkspace = backboneFixtures.workspace({ name: "im_also_the_current_one'", id: "987" });
                this.workspace = backboneFixtures.workspace({ name: "im_not_the_current_one", id: "123"});
                this.model = backboneFixtures.workspaceDataset.chorusView({ workspace: { id: "987" } });

                this.dialog = new chorus.dialogs.AssociateWithWorkspace({ model: this.model });
                this.dialog.render();

                this.server.completeFetchFor(chorus.session.user().workspaces(), [
                    this.currentWorkspace,
                    this.workspace,
                    backboneFixtures.workspace({ name: "yes_im_the_current_one", id: "645" })
                ]);

                spyOn(chorus, "toast");
                spyOn(chorus.router, "navigate");
                spyOn(this.dialog, "closeModal");

                this.dialog.$("li:eq(0)").click();
                this.dialog.$("button.submit").click();
            });

            it("calls the API for associating datasets with a workspace", function() {
                var lastCreate = this.server.lastCreate();
                var uri = new URI(lastCreate.url);

                expect(lastCreate.json()['dataset_ids']).toEqual([this.model.id]);
                expect(uri.path()).toEqual("/workspaces/" + this.workspace.get("id") + "/datasets");
                expect(uri.query(true)).toEqual({
                    page: '1',
                    per_page: '50'
                });
            });
        });
    });
});
