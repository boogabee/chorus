describe("chorus.collections.Base", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.Base([], { foo: "bar" });
        this.collection.urlTemplate = "bar/{{encode foo}}";
    });

    describe("#clone", function() {
        it ("copies the attributes as well as the models", function() {
            expect(this.collection.clone().attributes.foo).toEqual("bar");
        });
    });

    describe("#reset", function() {
        beforeEach(function() {
            this.collection = new chorus.collections.Base([{id: 123}]);
            this.collection.pagination = {records: 1};
        });

        it ("resets pagination.records on the collection", function() {
            this.collection.reset([]);
            expect(this.collection.pagination.records).toEqual(0);
        });

        it("accepts and sets pagination data", function() {
            this.collection.reset([], { pagination: 1});
            expect(this.collection.pagination).toEqual(1);
        });
    });

    describe("#url", function() {
        context("when the collection has pagination information from the server", function() {
            beforeEach(function() {
                this.collection.pagination = {
                    page: '4',
                    total: '5',
                    records: '250'
                };
            });

            it("fetches the corresponding page of the collection", function() {
                expect(this.collection.url()).toBe("/bar/bar?page=1&per_page=50");
            });
        });

        context("when the urlTemplate is a function", function() {
            beforeEach(function() {
                this.collection.urlTemplate = function() {
                    return "my_other_items/{{foo}}";
                };
            });

            it("uses the function's return value", function() {
                expect(this.collection.url()).toContain("/my_other_items/bar");
            });

            it("passes any options to the urlTemplate function", function() {
                spyOn(this.collection, 'urlTemplate').andReturn("foo");
                this.collection.url({ method: 'create' });
                expect(this.collection.urlTemplate).toHaveBeenCalledWith({per_page: 50, page: 1, method: 'create'});
            });
        });

        context("when the collection has NO pagination or page property", function() {
            it("fetches the first page of the collection", function() {
                expect(this.collection.url()).toBe("/bar/bar?page=1&per_page=50");
            });
        });

        it("does not unescape %2b to +, or otherwise bypass escaping", function() {
            this.collection.attributes.foo = "+";
            expect(this.collection.url()).toBe("/bar/%2B?page=1&per_page=50");
        });

        it("takes an optional page size", function() {
            expect(this.collection.url({ per_page: 1000 })).toBe("/bar/bar?page=1&per_page=1000");
        });

        it("takes an optional page number", function() {
            expect(this.collection.url({ page: 4 })).toBe("/bar/bar?page=4&per_page=50");
        });

        it("mixes in order from collection ascending", function() {
            this.collection.sortAsc("fooBar");
            expect(this.collection.url()).toBe("/bar/bar?page=1&per_page=50&order=foo_bar");
        });

        it("plays nicely with existing parameters in the url template", function() {
            this.collection.urlTemplate = "bar/{{foo}}?why=not";
            expect(this.collection.url()).toBe("/bar/bar?why=not&page=1&per_page=50");
        });

        context("when the collection has additional url params", function() {
            context("when the urlParams is a function", function() {
                beforeEach(function() {
                    this.collection.urlParams = function() {
                        return { dance: "the thizzle" };
                    };
                });

                it("passes any options to the urlParams function", function() {
                    spyOn(this.collection, 'urlParams').andCallThrough();
                    this.collection.url({ method: 'create' });
                    expect(this.collection.urlParams).toHaveBeenCalledWith({ method: 'create', per_page: 50, page: 1 });
                });
            });

            context("when the url params are a property", function() {
                beforeEach(function() {
                    this.collection.urlParams = { danceDance: "the thizzle" };
                });

                it("url-encodes the params and appends them to the url", function() {
                    expect(this.collection.url()).toMatchUrl("/bar/bar?dance_dance=the+thizzle&page=1&per_page=50");
                });

                context("when the base url template includes a query string", function() {
                    beforeEach(function() {
                        this.collection.urlTemplate = "bar/{{foo}}?roof=on_fire";
                    });

                    it("merges the query strings properly", function() {
                        expect(this.collection.url()).toMatchUrl("/bar/bar?roof=on_fire&dance_dance=the+thizzle&page=1&per_page=50");
                    });
                });
            });
        });

    });

    describe("before parsing", function() {
        it("is not loaded", function() {
            expect(this.collection.loaded).toBeFalsy();
        });
    });

    describe("#parse", function() {
        beforeEach(function() {
            this.things = [
                { hi: "there" },
                { go: "away" }
            ];
        });

        it("stores pagination info on the collection", function() {
            var pagination = {
                total: "2",
                page: "1",
                records: "52"
            };

            this.collection.parse({ response: this.things, pagination: pagination });
            expect(this.collection.pagination).toBe(pagination);
        });

        it("returns the enclosed resource", function() {
            expect(this.collection.parse({ response: this.things, status: 'ok'})).toEqual(this.things);
        });
    });

    describe("#remove", function() {
        context("with a paginated collection", function() {
            beforeEach(function(){
                this.collection.add([{}, {}, {}, {}]);
                this.collection.pagination = {
                    total: 1,
                    page: 1,
                    records: 4,
                    per_page: 50
                };
            });

            it('decreases the record count', function(){
                this.collection.remove(this.collection.at(0));
                expect(this.collection.totalRecordCount()).toBe(3);
            });

            it('takes an array of models', function() {
                this.collection.remove(this.collection.models);
                expect(this.collection.totalRecordCount()).toBe(0);
            });

            it('doesnt decrease the count for models that are not in the collection', function(){
                this.collection.remove({});
                expect(this.collection.totalRecordCount()).toBe(4);
            });
        });
    });

    describe("#findWhere", function() {
        beforeEach(function() {
            this.m1 = backboneFixtures.user({ firstName: "john", lastName: "coltrane", id: "5", admin: false });
            this.m2 = backboneFixtures.user({ firstName: "ravi", lastName: "coltrane", id: "6", admin: true });
            this.m3 = backboneFixtures.user({ firstName: "john", lastName: "medeski", id: "7", admin: true  });
            this.collection.reset([ this.m1, this.m2, this.m3 ]);
        });

        context("when a model with the given attributes exists in the collection", function() {
            it("returns the first matching model", function() {
                expect(this.collection.findWhere({ firstName: "john", lastName: "coltrane" })).toBe(this.m1);
                expect(this.collection.findWhere({ firstName: "john", admin: false })).toBe(this.m1);
                expect(this.collection.findWhere({ lastName: "coltrane", admin: true })).toBe(this.m2);
                expect(this.collection.findWhere({ firstName: "john", admin: true })).toBe(this.m3);
                expect(this.collection.findWhere({ lastName: "medeski" })).toBe(this.m3);
                expect(this.collection.findWhere({ admin: true })).toBe(this.m2);
            });
        });

        context("when no model with the given attributes exists in the collection", function() {
            it("returns undefined", function() {
                expect(this.collection.findWhere({ firstName: "ravi", lastName: "medeski" })).toBeUndefined();
            });
        });
    });

    describe("#fetchAll", function() {
        beforeEach(function() {
            this.collection.fetchAll();
        });

        it("requests page one from the server", function() {
            expect(this.server.requests[0].url).toBe("/bar/bar?page=1&per_page=1000");
        });

        describe("and the server responds successfully", function() {
            beforeEach(function() {
                var self = this;

                this.resetListener = jasmine.createSpy("reset");
                this.resetListener.andCallFake(function(collection) {
                    self.collectionLengthOnReset = collection.length;
                });
                this.collection.bind("reset", this.resetListener);

                this.loadedListener = jasmine.createSpy("loaded");
                this.loadedListener.andCallFake(function() {
                    self.collectionLengthOnLoaded = this.length;
                });
                this.collection.bind("loaded", this.loadedListener);

                this.serverRespondedSpy = jasmine.createSpy("serverResponded");
                this.collection.bind("serverResponded", this.serverRespondedSpy);

                this.server.fetches()[0].succeed([
                    { foo: "first" },
                    { foo: "second" }
                ],
                    {
                        "total": "2",
                        "page": "1",
                        "records": "3"
                    }
                );

                this.server.fetches()[1].succeed([
                    { foo: "third" }
                ],
                    {
                        "total": "2",
                        "page": "2",
                        "records": "3"
                    }
                );
            });

            it("requests subsequent pages", function() {
                expect(this.server.requests[1].url).toBe("/bar/bar?page=2&per_page=1000");
            });

            it("triggers the reset event once", function() {
                expect(this.resetListener.calls.count()).toBe(1);
            });

            it("triggers the reset event after all models are in the collection", function() {
                expect(this.collectionLengthOnReset).toBe(3);
            });

            it("triggers the loaded event once", function() {
                expect(this.loadedListener.calls.count()).toBe(1);
            });

            it("triggers serverResponded once", function() {
                expect(this.serverRespondedSpy.calls.count()).toBe(1);
            });

            it("triggers the loaded event after all models are in the collection", function() {
                expect(this.collectionLengthOnLoaded).toBe(3);
            });
        });

        describe("and the server responds with an error", function() {
            beforeEach(function() {
                var self = this;

                this.resetListener = function(collection) {
                    self.collectionLengthOnReset = collection.length;
                };
                this.collection.bind("reset", this.resetListener);

                this.server.fetches()[0].succeed([
                    { foo: "hi" },
                    { foo: "there" }
                ],
                    {
                        "total": "2",
                        "page": "1",
                        "records": "3"
                    }
                );

                this.server.fetches()[1].failUnprocessableEntity();
            });

            it("requests subsequent pages", function() {
                expect(this.server.requests[1].url).toBe("/bar/bar?page=2&per_page=1000");
            });

            it("triggers the reset event when the error occurs", function() {
                expect(this.collectionLengthOnReset).toBe(2);
            });
        });
    });

    describe("#fetchPage", function() {
        it("requests page one from the server", function() {
            this.collection.fetchPage(2);
            expect(this.server.requests[0].url).toBe("/bar/bar?page=2&per_page=50");
        });

        it("passes options through to fetch", function() {
            spyOn(this.collection, "fetch");
            this.collection.fetchPage(2, { foo: "bar" });
            var options = this.collection.fetch.lastCall().args[0];
            expect(options.foo).toBe("bar");
        });

        it("does not affect subsequent calls to fetch", function() {
            this.collection.fetchPage(2);
            this.collection.fetch();
            expect(this.server.requests[1].url).toBe("/bar/bar?page=1&per_page=50");
        });

        context("when the 'per_page' option is passed", function() {
            it("fetches the given number of rows", function() {
                this.collection.fetchPage(2, { per_page: 13 });
                expect(this.server.lastFetch().url).toBe("/bar/bar?page=2&per_page=13");
            });

            it("does not pass the 'per_page' option through to Backbone.Collection#fetch", function() {
                spyOn(this.collection, "fetch");
                this.collection.fetchPage(2, { per_page: 13 });
                var options = this.collection.fetch.lastCall().args[0];
                expect(options.per_page).toBeUndefined();
            });

            it("stores the number of rows, and fetches number next time", function() {
                this.collection.fetchPage(2, { per_page: 13 });
                this.collection.fetchPage(3);
                expect(this.server.lastFetch().url).toBe("/bar/bar?page=3&per_page=13");

                this.collection.fetch();
                expect(this.server.lastFetch().url).toContainQueryParams({ per_page: 13 });
            });
        });

        it("fires a paginate event after fetch succeeds", function() {
            spyOnEvent(this.collection, "paginate");
            this.collection.fetchPage(2, { foo: "bar" });
            expect("paginate").not.toHaveBeenTriggeredOn(this.collection);
            this.server.lastFetch().succeed();
            expect("paginate").toHaveBeenTriggeredOn(this.collection);
        });
    });

    describe("#totalRecordCount", function() {
        it("uses the pagination records number when pagination exists", function() {
            this.collection.pagination = { page: 1, total: 1, records: 100 };
            expect(this.collection.totalRecordCount()).toBe(100);
        });

        it("users the models lengths when pagination does not exists", function() {
            this.collection.add(new chorus.models.Base());
            expect(this.collection.totalRecordCount()).toBe(1);
        });

    });
    describe("LastFetchWins", function() {
        beforeEach(function() {
            this.collection = new chorus.collections.LastFetchWins([], { foo: "bar" });
            this.collection.urlTemplate = "lifo/{{foo}}";
        });
        it("ignores values returned by previous fetches", function() {
            var foo = {x: 0};
            this.collection.fetch({success: _.bind(function() {
                this.x = 1;
            }, foo)});
            var fetch1 = this.server.lastFetchFor(this.collection);

            this.collection.fetch({success: _.bind(function() {
                this.x = 2;
            }, foo)});
            var fetch2 = this.server.lastFetchFor(this.collection);

            expect(foo.x).toBe(0);

            fetch2.succeed([], {});
            expect(foo.x).toBe(2);

            fetch1.succeed([], {});
            expect(foo.x).toBe(2);

            this.collection.fetch({success: _.bind(function() {
                this.x = 3;
            }, foo)});
            var fetch3 = this.server.lastFetchFor(this.collection);

            fetch3.succeed([], {});
            expect(foo.x).toBe(3);
        });
    });

    describe("#shouldTriggerImmediately", function() {
        context("when the argument is 'loaded'", function() {
            it("returns true if the model is loaded", function() {
                this.collection.loaded = true;
                expect(this.collection.shouldTriggerImmediately("loaded")).toBeTruthy();
            });
            it("returns false if the model is NOT loaded", function() {
                this.collection.loaded = false;
                expect(this.collection.shouldTriggerImmediately("loaded")).toBeFalsy();
            });
        });
        it("returns false for any other arguments", function() {
            _.each(["change", "reset", "saveFailed", "validationFailed"], function(eventName) {
                expect(this.collection.shouldTriggerImmediately(eventName)).toBeFalsy();
            }, this);
        });

    });

    describe("#updateTags", function() {
        beforeEach(function() {
            this.model1 = backboneFixtures.workfile.sql({id: "123", tags: [
                {name: "tag1"},
                {name: "tag2"}
            ]});
            this.model2 = backboneFixtures.workfile.sql({id: "456", tags: [
                {name: "tag1"},
                {name: "tag3"}
            ]});
            this.collection = backboneFixtures.workfileSet();
            this.collection.reset([this.model1, this.model2]);
            this.tag = new chorus.models.Tag({name: 'foo'});
            this.fakeTaggingsUpdater = new chorus.models.TaggingsUpdater({collection: this.collection});
            spyOn(this.fakeTaggingsUpdater, "updateTags");
            spyOn(chorus.models, "TaggingsUpdater").andReturn(this.fakeTaggingsUpdater);
        });

        it("removes and saves tags for each model in the collection", function() {
            this.collection.updateTags({remove: this.tag});

            expect(chorus.models.TaggingsUpdater).toHaveBeenCalledWith({collection: this.collection});
            expect(this.fakeTaggingsUpdater.updateTags).toHaveBeenCalledWith({remove: this.tag});
        });

        it("adds and saves tags for each model in the collection", function() {
            this.collection.updateTags({add: this.tag});

            expect(chorus.models.TaggingsUpdater).toHaveBeenCalledWith({collection: this.collection});
            expect(this.fakeTaggingsUpdater.updateTags).toHaveBeenCalledWith({add: this.tag});
        });

        context("when updating tags fails", function() {
            beforeEach(function() {
                spyOnEvent(this.collection, 'updateTagsFailed');
                this.failingTaggings = {};
                this.collection.updateTags({remove: this.tag});
                spyOn(this.model1.tags(), 'fetchAll');
                spyOn(this.model2.tags(), 'fetchAll');
                this.fakeTaggingsUpdater.trigger('updateFailed', this.failingTaggings);
            });

            it("triggers a updateTagsFailed event", function() {
                expect('updateTagsFailed').toHaveBeenTriggeredOn(this.collection, [this.failingTaggings]);
            });

            it("re-fetches tags for all items in collection", function() {
                expect(this.model1.tags().fetchAll).toHaveBeenCalled();
                expect(this.model2.tags().fetchAll).toHaveBeenCalled();
            });
        });
    });

    describe("#destroy", function () {
        beforeEach(function () {
            var model = backboneFixtures.job();
            var model2 = backboneFixtures.job({id: "foo"});
            this.collection.add([model, model2]);
        });

        it("deletes all of its models", function () {
            this.collection.each(function (model) {
                spyOn(model, 'destroy');
            });

            this.collection.destroy();

            this.collection.each(function (model) {
                expect(model.destroy).toHaveBeenCalled();
            });


        });
    });
});

