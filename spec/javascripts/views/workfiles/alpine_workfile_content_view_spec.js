describe("chorus.views.AlpineWorkfileContent", function() {
    beforeEach(function() {
        this.model = backboneFixtures.workfile.alpine();
        this.view = new chorus.views.AlpineWorkfileContent({ model: this.model });
        this.view.render();
    });

    it("shows the image from alpine", function() {
        expect(this.view.$('img')).toHaveAttr('src', this.model.imageUrl());
    });
});