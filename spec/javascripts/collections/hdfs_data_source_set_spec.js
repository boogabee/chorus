describe("chorus.collections.HdfsDataSourceSet", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.HdfsDataSourceSet();
    });

    it("has the right url", function() {
        expect(this.collection.url()).toHaveUrlPath("/hdfs_data_sources");
    });

    describe("#urlParams", function() {
        it("contains the 'succinct' attribute", function() {
            expect(this.collection.urlParams().succinct).toBeUndefined();
            this.collection.attributes.succinct = true;
            expect(this.collection.urlParams().succinct).toBe(true);
        });

        it("includes the 'jobTracker' attribute when specified", function() {
            expect(this.collection.urlParams().jobTracker).toBeUndefined();
            this.collection.attributes.jobTracker = true;
            expect(this.collection.urlParams().jobTracker).toBe(true);
        });
    });
});
