describe("chorus.views.SchemaListSidebar", function() {
    beforeEach(function() {
        this.view = new chorus.views.SchemaListSidebar();
    });

    it("does not show an info section", function () {
        expect(this.view.$('.info')).not.toExist();
    });

});

