describe("chorus.views.KaggleUserItem", function() {
    beforeEach(function() {
        this.model = backboneFixtures.kaggleUserSet([
            {
                fullName: "Joe Kaggle",
                location: "San Francisco",
                rank: 5,
                gravatarUrl: "http://example.com/images/user.img"
            }
        ]).at(0);
        this.view = new chorus.views.KaggleUserItem({model: this.model});
        this.view.render();
    });

    it("displays the names", function() {
        expect(this.view.$(".name")).toHaveText("Joe Kaggle");
    });

    it("displays the location", function() {
        expect(this.view.$(".location")).toHaveText("San Francisco");
    });

    it("displays the rank", function() {
        expect(this.view.$(".kaggle_rank")).toHaveText("5");
    });

    it("displays the gravatar url when the user has one", function() {
        expect(this.view.$("img")).toHaveAttr("src", "http://example.com/images/user.img");
    });

    it("displays the default gravatar image when the user does not have one", function() {
        this.model.set({gravatarUrl: ''});
        this.view.render();
        expect(this.view.$("img")).toHaveAttr("src", "/images/kaggle/default_user.jpeg");
    });
});