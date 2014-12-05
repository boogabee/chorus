describe("chorus.views.ReadOnlyTextContent", function() {
    beforeEach(function() {
        this.file = backboneFixtures.hdfsFile();
        this.view = new chorus.views.ReadOnlyTextContent({ model: this.file });
    });

    describe("#render", function() {
        beforeEach(function() {
            spyOn(this.file, 'content').andReturn("My secret content\nnext line");
            this.view.render();
        });

        it("shows the text", function() {
            expect(this.view.$(".file_content").text()).toBe("My secret content\nnext line");
        });
    });
});