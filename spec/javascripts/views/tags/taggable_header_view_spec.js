describe("chorus.views.TaggableHeader", function() {
    beforeEach(function() {
        this.model = new chorus.models.Base({
            name: 'ImAModel',
            tags: [
                {name: "taggingTagTag"}
            ]
        });
        this.model.iconUrl = function() { return "http://bestpicture.com"; };
        this.model.statusCode = 200;

        this.view = new chorus.views.TaggableHeader({model: this.model});
        this.view.render();
    });

    it("shows the model name", function() {
        expect(this.view.$el).toContainText(this.model.name());
    });

    it("has tags", function() {
        expect(this.view.$('.text-tags')).toContainText("taggingTagTag");
    });

    it("shows the model icon", function() {
        expect(this.view.$('img')).toHaveAttr('src', this.model.iconUrl());
    });
});