describe("chorus.utilities.TagItemManager", function() {
    beforeEach(function() {
        this.manager = new chorus.utilities.TagItemManager();
        this.manager.init({_opts:{}});
    });

    describe("#filter", function() {
        it("returns whatever is given as the first parameter", function() {
            expect(this.manager.filter('foo', 'bar')).toEqual('foo');
        });
    });

    describe("#itemContains", function() {
        it("returns true because we filter on the server", function() {
            expect(this.manager.itemContains({name: 'bar'}, 'baz')).toEqual(true);
        });
    });

    describe("#stringToItem", function() {
        it("returns an object whose name is the string", function() {
            expect(this.manager.stringToItem('bar')).toEqual({name: 'bar'});
        });
    });

    describe("#itemToString", function() {
        it("returns the name", function() {
            expect(this.manager.itemToString({name: 'foo'})).toEqual('foo');
        });
    });

    describe("#compareItems", function() {
        it("compares the names of the items case insensitively", function() {
            expect(this.manager.compareItems({name: 'foo'}, {name: 'bar'})).toEqual(false);
            expect(this.manager.compareItems({name: 'baz'}, {name: 'BAZ'})).toEqual(true);
        });
    });
});