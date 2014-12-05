describe("chorus.models.HdfsEntryStatistics", function() {
    describe("#url", function() {
        beforeEach(function() {
            this.datasetStatistics = new chorus.models.HdfsEntryStatistics({ entryId: 1, hdfsDataSourceId: 2 });
        });

        it("should call the right API", function() {
            expect(this.datasetStatistics.url()).toMatchUrl("/hdfs_data_sources/2/files/1/statistics");
        });
    });
});
