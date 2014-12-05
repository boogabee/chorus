describe("chorus.models.BulkDestroyer", function() {
    describe("#destroy", function() {
        var collection, destroyer;

        beforeEach(function() {
            collection = new chorus.collections.Base();
            collection.urlTemplate = "the/collections/url";

            destroyer = new chorus.models.BulkDestroyer({collection: collection});
        });

        it("submits to its collection's url", function() {
            destroyer.destroy();
            expect(this.server.lastDestroy().url).toHaveUrlPath("/the/collections/url");
        });

        it("sends additional options in the 'data' parameter with snaked keys", function() {
            destroyer.destroy({fooParam: 'barValue'});
            expect(this.server.lastDestroy().json()['foo_param']).toEqual('barValue');
        });

        it("sends arrays", function() {
            destroyer.destroy({datasetIds: ['barValue', 'varBalue']});
            expect(this.server.lastDestroy().json()['dataset_ids']).toEqual(['barValue', 'varBalue']);
        });

        it("triggers destroy on the collection", function() {
            spyOnEvent(collection, "destroy");
            destroyer.destroy();
            this.server.lastDestroy().succeed();
            expect("destroy").toHaveBeenTriggeredOn(collection);
        });

        it("triggers destroyFailed on the collection", function() {
            spyOnEvent(collection, "destroyFailed");
            destroyer.destroy();
            this.server.lastDestroy().failUnprocessableEntity();
            expect("destroyFailed").toHaveBeenTriggeredOn(collection);
        });
    });
});