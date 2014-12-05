describe("chorus.collections.Search", function() {
    beforeEach(function() {
        this.search = backboneFixtures.searchResult({
            dataSources: {
                numFound: 131,
                results: [
                    chorus.Mixins.Fetching.camelizeKeys(backboneFixtures.gpdbDataSourceJson({ response: { name: "dataSource101", id: '101' } }).response),
                    chorus.Mixins.Fetching.camelizeKeys(backboneFixtures.jdbcDataSourceJson({ response: { name: "dataSource102", id: '102' } }).response),
                    chorus.Mixins.Fetching.camelizeKeys(backboneFixtures.hdfsDataSourceJson({ response: { name: "dataSource103", id: '103' } }).response),
                    chorus.Mixins.Fetching.camelizeKeys(backboneFixtures.gnipDataSourceJson({ response: { name: "dataSource104", id: '104' } }).response),
                    chorus.Mixins.Fetching.camelizeKeys(backboneFixtures.gpdbDataSourceJson({ response: { name: "dataSource105", id: '105' } }).response),
                    chorus.Mixins.Fetching.camelizeKeys(backboneFixtures.gpdbDataSourceJson({ response: { name: "dataSource106", id: '106' } }).response)
                ]
            }
        });
        this.collection = new chorus.collections.Search.DataSourceSet([], {search: this.search});
    });

    describe("#refreshFromSearch", function() {
        beforeEach(function() {
            var collection = this.collection;
            this.spy = jasmine.createSpy("resetSpy").andCallFake(function() {
                expect(collection.pagination.records).toBe(131);
                expect(collection.pagination.total).toBe(3);
                expect(collection.pagination.page).toBe(1);
            });
            this.collection.bind("reset", this.spy);
            this.collection.refreshFromSearch();
        });

        it("populates the collection with the right data from the search", function() {
            expect(this.collection.length).toBe(6);
            expect(this.collection.at(0).get('id')).toBe('101');
            expect(this.collection.at(1).get('id')).toBe('102');
            expect(this.collection.at(2).get('id')).toBe('103');
            expect(this.collection.at(3).get('id')).toBe('104');
            expect(this.collection.at(4).get('id')).toBe('105');
            expect(this.collection.at(5).get('id')).toBe('106');
        });

        it("sets the collection's pagination information correctly, *before* triggering a reset", function() {
            expect(this.spy).toHaveBeenCalled();
            this.spy();
        });
    });

    describe("#fetchPage", function() {
        beforeEach(function() {
            this.collection.fetchPage(5);
        });

        it("fetches the correct page of search results", function() {
            expect(this.server.lastFetch().url).toBe(this.search.url({ page: 5 }));
        });

        it("refreshes the collection on success", function() {
            this.server.completeFetchFor(this.search, new chorus.models.SearchResult({
                dataSources: {
                    numFound: 51,
                    results: [
                        backboneFixtures.gpdbDataSourceJson({ response: { name: "dataSource121", id: '121' } }).response,
                        backboneFixtures.gpdbDataSourceJson({ response: { name: "dataSource122", id: '122' } }).response,
                        backboneFixtures.gpdbDataSourceJson({ response: { name: "dataSource123", id: '123' } }).response
                    ]
                }
            }));

            expect(this.collection.pagination.records).toBe(51);
            expect(this.collection.length).toBe(3);
            expect(this.collection.at(0).get("id")).toBe("121");
            expect(this.collection.at(1).get("id")).toBe("122");
            expect(this.collection.at(2).get("id")).toBe("123");
        });
    });
});
