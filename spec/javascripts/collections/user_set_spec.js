describe("chorus.collections.UserSet", function() {
    beforeEach(function() {
        this.collection = backboneFixtures.userSet();
    });

    it("has the correct urlTemplate", function() {
        expect(this.collection.urlTemplate).toBe("users/");
    });
});
