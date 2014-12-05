describe("chorus.collections.TagSet", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.TagSet([
            {name: "foo"},
            {name: "bar"}
        ]);
    });

    it("has the right url", function() {
        expect(this.collection.url()).toHaveUrlPath("/tags");
    });
});