describe("chorus.models.TaggingsUpdater", function() {
    beforeEach(function(){
        this.entity1 = backboneFixtures.dataset({id: 123});
        this.entity2 = backboneFixtures.dataset({id: 456});
        this.collection = new chorus.collections.Base([this.entity1.attributes, this.entity2.attributes]);
        this.tag = new chorus.models.Tag({name: "foo"});

        this.taggingsUpdater = new chorus.models.TaggingsUpdater({collection: this.collection});

        spyOnEvent(this.taggingsUpdater, "updated");
        spyOnEvent(this.taggingsUpdater, "updateFailed");
    });

    describe("adding a tag", function() {
        beforeEach(function() {
            this.taggingsUpdater.updateTags({add: this.tag});
        });

        it("posts to taggings", function() {
            expect(this.server.lastCreate().url).toHaveUrlPath("/taggings");
        });

        it("posts the added tag to the taggings for all objects", function() {
            var json = this.server.lastCreate().json();
            expect(json["taggables"][0]["entity_id"]).toEqual(123);
            expect(json["taggables"][1]["entity_id"]).toEqual(456);
            expect(json["add"]).toEqual('foo');
            expect(json["remove"]).toBeUndefined();
        });

        context("when the update succeeds", function() {
            beforeEach(function() {
                this.server.lastCreate().succeed();
            });

            it("triggers updated on the tagging set array", function() {
                expect("updated").toHaveBeenTriggeredOn(this.taggingsUpdater);
            });
        });

        context("when the update failed", function() {
            beforeEach(function() {
                spyOn(chorus, "toast");
                this.server.lastCreate().failForbidden();
            });

            it("triggers updateFailed on the taggings", function() {
                expect("updateFailed").toHaveBeenTriggeredOn(this.taggingsUpdater);
            });

            it("pops up a toast", function() {
                expect(chorus.toast).toHaveBeenCalled();
            });
        });

        context("when a second request is queued", function() {
            beforeEach(function() {
                var tag2 = new chorus.models.Tag({name: "bar"});
                this.taggingsUpdater.updateTags({add: tag2});
            });

            it("only saves the second tag after the first tag completes saving", function() {
                expect(this.server.requests.length).toBe(1);
                this.server.lastCreate().succeed();
                expect(this.server.requests.length).toBe(2);
            });

            context("when the initial tagging request fails", function() {
                beforeEach(function() {
                    var tag2 = new chorus.models.Tag({name: "bar"});
                    this.taggingsUpdater.updateTags({add: tag2});
                    this.server.lastCreate().failForbidden();
                });

                it("doesn't send requests that are already queued", function() {
                    expect(this.server.requests.length).toBe(1);
                });

                it("still allows new requests to be made", function() {
                    this.server.reset();
                    var tag3 = new chorus.models.Tag({name: "baz"});
                    this.taggingsUpdater.updateTags({add: tag3});
                    expect(this.server.requests.length).toBe(1);
                });
            });
        });
    });

    describe("removing a tag", function() {
        beforeEach(function() {
            this.taggingsUpdater.updateTags({remove: this.tag});
        });

        it("posts the remove tag options to taggings for all objects", function() {
            var json = this.server.lastCreate().json();
            expect(json["taggables"][0]["entity_id"]).toEqual(123);
            expect(json["taggables"][1]["entity_id"]).toEqual(456);
            expect(json["remove"]).toEqual('foo');
            expect(json["add"]).toBeUndefined();
        });
    });
});
