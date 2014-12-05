describe("chorus.collections.TaggingSet", function() {
    beforeEach(function() {
        this.model = new chorus.models.Base({id: 33});
        this.model.entityType = "modelClass";

        this.collection = new chorus.collections.TaggingSet([
            {name: "foo"},
            {name: "bar"}
        ], { entity: this.model });
    });

    it("has the right url", function() {
        expect(this.collection.url()).toHaveUrlPath("/taggings");
        expect(this.collection.url()).toContainQueryParams({entity_id: 33, entity_type: 'modelClass'});
    });

    describe('#add', function() {
        context("when called with a tag that already exists", function(){
            beforeEach(function(){
                this.collection.add({name: "foo"});
            });

            it("does not add a new tag", function(){
                expect(this.collection.length).toBe(2);
            });
        });
    });
});