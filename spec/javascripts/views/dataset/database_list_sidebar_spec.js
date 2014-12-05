describe("chorus.views.DatabaseListSidebar", function() {
    beforeEach(function() {
        this.view = new chorus.views.DatabaseListSidebar();
        chorus.PageEvents.trigger("database:selected", backboneFixtures.database());
    });

    it("does not show an info section", function () {
        expect(this.view.$('.info')).not.toExist();
    });
});
