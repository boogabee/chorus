describe("chorus.views.DatasetEditChorusViewSidebar", function() {
    beforeEach(function() {
        chorus.page = { workspace: backboneFixtures.workspace() };
        this.dataset = backboneFixtures.workspaceDataset.chorusView();
        this.view = new chorus.views.DatasetEditChorusViewSidebar({model: this.dataset });
        this.server.completeAllFetches();
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view.model.fetch();
            this.server.completeFetchFor(this.dataset);
            this.view.render();
        });

        it("should have an activities tab", function() {
            expect(this.view.$('.tab_control .activity_list')).toExist();
            expect(this.view.tabs.activity).toBeA(chorus.views.ActivityList);
        });

        it("should have a functions tab", function() {
            expect(this.view.$('.tab_control .function_tab')).toExist();
            expect(this.view.tabs.database_function_list).toBeA(chorus.views.FunctionTab);
        });

        it("should have a dataset tab", function() {
            expect(this.view.$('.tab_control .data_tab')).toExist();
            expect(this.view.tabs.data).toBeA(chorus.views.DataTab);
        });

        it("sets the default tab to data tab", function () {
            expect(this.view.$(".tab_control .selected")).toContainTranslation("tabs.data");
        });
    });
});
