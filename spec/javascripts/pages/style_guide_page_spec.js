describe("chorus.pages.StyleGuidePage", function() {
    beforeEach(function () {
        this.page = new chorus.pages.StyleGuidePage();
    });

    it("has a SiteElementsView", function () {
        expect(this.page.mainContent.content).toBeA(chorus.pages.StyleGuidePage.SiteElementsView);
    });
});