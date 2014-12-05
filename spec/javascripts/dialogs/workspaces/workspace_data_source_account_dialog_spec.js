describe("chorus.dialogs.WorkspaceDataSourceAccount", function() {
    beforeEach(function() {
        this.workspace = backboneFixtures.workspace();
        this.account = backboneFixtures.dataSourceAccount();
        this.dialog = new chorus.dialogs.WorkspaceDataSourceAccount({ model: this.account, pageModel: this.workspace});
        this.dialog.render();
    });

    describe("#render", function() {
        it("has the right title", function() {
            expect(this.dialog.title).toMatchTranslation("workspace.data_source.account.title");
        });

        it("has the right cancel text", function() {
            expect(this.dialog.$('button.cancel')).toContainTranslation("workspace.data_source.account.continue_without_credentials");
        });

        it("has the right body text", function() {
            expect(this.dialog.$('.dialog_content')).toContainTranslation("workspace.data_source.account.body", {dataSourceName: this.workspace.sandbox().database().dataSource().get("name")});
        });
    });
});
