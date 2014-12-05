describe("chorus.views.KaggleUserInformation", function() {
    beforeEach(function() {
        this.model = backboneFixtures.kaggleUserSet().at(0);
        this.model.set({favoriteTechnique: "my favorite technique"});
        this.model.set({favoriteSoftware: "javascript!"});
        this.view = new chorus.views.KaggleUserInformation({model: this.model});
        this.view.render();
    });

    it("shows the user's rank", function() {
        expect(this.view.$(".pair")).toContainText(this.model.get("rank"));
    });

    it("shows the user's points", function() {
        expect(this.view.$(".pair")).toContainText(this.model.get("points"));
    });

    it("shows the user's entered competitions", function() {
        expect(this.view.$(".pair")).toContainText(this.model.get("numberOfEnteredCompetitions"));
    });

    it("shows the user's past competition types", function() {
        expect(this.view.$(".pairs .value")).toContainText(this.model.get("pastCompetitionTypes")[0]);
    });

    it("shows the user's favorite technique", function() {
        expect(this.view.$(".pairs")).toContainText("my favorite technique");
    });

    it("shows the user's favorite software", function() {
        expect(this.view.$(".pairs")).toContainText("javascript!");
    });

    context("When favorite technique is not specified", function() {
        beforeEach(function() {
            this.model.set({favoriteTechnique: null});
            this.view.render();
        });
        it("doesn't show favorite technique key", function() {
            expect(this.view.$(".pairs")).not.toContainTranslation("kaggle.information.favorite_technique");
        });
    });

    context("When favorite software is not specified", function() {
        beforeEach(function() {
            this.model.set({favoriteSoftware: null});
            this.view.render();
        });
        it("doesn't show favorite software key", function() {
            expect(this.view.$(".pairs")).not.toContainTranslation("kaggle.information.favorite_software");
        });
    });
});