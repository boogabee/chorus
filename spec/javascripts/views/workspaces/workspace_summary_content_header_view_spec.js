describe("chorus.views.WorkspaceSummaryContentHeader", function() {
    beforeEach(function() {
        this.workspace = backboneFixtures.workspace();
        this.workspace.loaded = true;
        this.view = new chorus.views.WorkspaceSummaryContentHeader({model: this.workspace});
    });

    it("fetches the workspace's activity", function() {
        expect(this.workspace.activities()).toHaveBeenFetched();
    });

    describe("#render", function() {
        beforeEach(function() {
            this.server.completeFetchFor(this.workspace.activities());
            this.view.render();
        });

        it("displays the workspace title", function() {
            expect(this.view.$(".workspace_title")).toContainText(this.workspace.get("name"));
        });

        it("fills the activityListHeader subview", function() {
            expect(this.view.$(".activity_list_header")).not.toBeEmpty();
        });

        it("fills the project status subview", function(){
            expect(this.view.$(".project_status")).toContainTranslation('workspace.project.status.label');
            expect(this.view.$(".project_status")).toContainTranslation('workspace.project.status.on_track');
        });

        it("has a truncated text view with the workspace's summary", function() {
            expect(this.view.$(this.view.truncatedSummary.el)).toExist();
            expect(this.view.truncatedSummary.el).not.toBeEmpty();
            expect(this.view.truncatedSummary).toBeA(chorus.views.TruncatedText);

            expect(this.view.truncatedSummary.options.model).toBe(this.workspace);
            expect(this.view.truncatedSummary.options.attribute).toBe("summary");
            expect(this.view.truncatedSummary.options.extraLine).toBeTruthy();

        });

        it("hides the summary if the workspace does not have one", function() {
            this.view.model.unset("summary");
            this.view.render();
            expect(this.view.$(".truncated_summary")).toHaveClass("hidden");
        });

        it("displays the correct title", function() {
            expect(this.view.$(".workspace_title")).toContainText(this.workspace.get("name"));
        });
    });

    describe("when the model is saved", function() {
        it("calls render", function() {
            spyOn(this.view, 'render');
            this.view.model.trigger("saved");
            expect(this.view.render).toHaveBeenCalled();
        });

        it("updates the activity list header", function() {
            this.view.model.set({name: "super workspace"});
            this.view.model.trigger("saved");

            expect(this.view.$(".activity_list_header .workspace_title")).toContainText("super workspace");
        });
    });

    describe("#resourcesLoaded", function() {
        it("passes a TagBox to activityListHeader", function() {
            this.view.resourcesLoaded();
            expect(this.view.activityListHeader.options.tagBox.options.model).toBe(this.workspace);
            expect(this.view.activityListHeader.options.tagBox.options.workspaceIdForTagLink).toBe(this.workspace.id);
        });
    });
});
