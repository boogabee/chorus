chorus.models.HdfsEntryStatistics = chorus.models.Base.extend({
    constructorName: "HdfsEntryStatistics",
    urlTemplate: "hdfs_data_sources/{{hdfsDataSourceId}}/files/{{entryId}}/statistics"
});