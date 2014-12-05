describe("chorus.collections.FilteringCollection", function() {
    beforeEach(function() {
        this.extraModel = new chorus.models.Base({name: 'baz'});
        this.childCollection = new Backbone.Collection([new chorus.models.Base({name: 'foo'}), new chorus.models.Base({name: 'bar'})]);
        this.collection = new chorus.collections.FilteringCollection(null, {
            collection: this.childCollection
        });
    });

    it("should throw an error if constructed with models", function () {
        var childCollection = this.childCollection;
        expect(function () {
            return new chorus.collections.FilteringCollection([], {collection : childCollection});
        }).toThrow("Must initialize FilteringCollection with null");
    });

    it("should throw an error if constructed without a child collection", function () {
        expect(function () {
            return new chorus.collections.FilteringCollection(null);
        }).toThrow("Must initialize FilteringCollection with a child collection");
    });

    it("initializes it's models to the child collections models", function () {
        expect(this.collection.pluck('name')).toEqual(this.childCollection.pluck('name'));
    });

    describe("when the child collection is loaded", function () {
        beforeEach(function () {
            this.childCollection.add(this.extraModel, {silent: true});
        });

        it("updates it's collection", function () {
            this.childCollection.trigger('loaded');
            expect(this.collection.pluck('name')).toEqual(this.childCollection.pluck('name'));
        });

        it("marks itself loaded and triggers 'loaded'", function () {
            var loaded = jasmine.createSpy('loaded');
            this.collection.on('loaded', loaded);
            this.childCollection.trigger('loaded');
            expect(loaded).toHaveBeenCalled();
            expect(this.collection.loaded).toBe(true);
        });

        context("when there is a search term already applied", function () {
            beforeEach(function () {
                this.collection.search('ba');
                this.childCollection.trigger('loaded');
            });

            it("filter correctly", function () {
                this.childCollection.trigger('reset');
                expect(this.collection.pluck('name')).toEqual(['bar', 'baz']);
            });
        });
    });

    describe("when the child collection's fetch responds", function () {
        it("updates it's status code and triggers 'serverResponded'", function () {
            var loaded = jasmine.createSpy('serverResponded');
            this.collection.on('serverResponded', loaded);
            this.childCollection.statusCode = 123;
            this.childCollection.trigger('serverResponded');
            expect(loaded).toHaveBeenCalled();
            expect(this.collection.statusCode).toBe(123);
        });
    });

    describe("when the child collection is reset", function () {
        beforeEach(function () {
            this.childCollection.add(this.extraModel, {silent: true});
        });

        it("updates it's collection", function () {
            this.childCollection.trigger('reset');
            expect(this.collection.pluck('name')).toEqual(this.childCollection.pluck('name'));
        });

        context("when there is a search term already applied", function () {
            beforeEach(function () {
                this.collection.search('ba');
                this.childCollection.trigger('reset');
            });

            it("filter correctly", function () {
                this.childCollection.trigger('reset');
                expect(this.collection.pluck('name')).toEqual(['bar', 'baz']);
            });
        });
    });

    describe("#search", function() {
        it("filters the child collection", function () {
            this.collection.search('ba');
            expect(this.collection.pluck('name')).toEqual(['bar']);
        });

        it("triggers 'searched'", function() {
            var searched = jasmine.createSpy('searched');
            this.collection.on('searched', searched);
            this.collection.search("search term");
            expect(searched).toHaveBeenCalled();
        });
    });

    describe("passing through collection methods", function () {
        it("passes fetch through", function () {
            spyOn(Backbone.Collection.prototype, 'fetch');
            this.collection.fetch("foo");
            expect(this.childCollection.fetch).toHaveBeenCalledWith("foo");
        });

        it("passes fetchAll through", function () {
            Backbone.Collection.prototype.fetchAll = jasmine.createSpy('fetchAll');
            this.collection.fetchAll("foo");
            expect(this.childCollection.fetchAll).toHaveBeenCalledWith("foo");
        });

        it("passes url through", function () {
            Backbone.Collection.prototype.url = jasmine.createSpy('url');
            this.collection.url("foo");
            expect(this.childCollection.url).toHaveBeenCalledWith("foo");
        });

        it("passes remove through", function () {
            spyOn(Backbone.Collection.prototype, 'remove');
            this.collection.remove("foo");
            expect(this.childCollection.remove).toHaveBeenCalledWith("foo");
        });

        it("still removes from itself", function () {
            this.collection.remove(this.childCollection.first());
            expect(this.collection.length).toEqual(1);
        });

    });
});
