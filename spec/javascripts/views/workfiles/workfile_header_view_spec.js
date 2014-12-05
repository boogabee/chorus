describe("chorus.views.WorkfileHeader", function() {
    beforeEach(function() {
        this.model = backboneFixtures.workfile.sql({
            tags: [{name: "alpha"}],
            workspace: {id: 123}
        });
        this.view = new chorus.views.WorkfileHeader({model: this.model});
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view.render();
        });

        it("has tags", function() {
            expect(this.view.$('.text-tags')).toContainText("alpha");
        });

        it("has passes the workspace id for tag links to the tag box", function() {
            expect(this.view.tagBox.options.workspaceIdForTagLink).toBe(123);
        });
    });
});
