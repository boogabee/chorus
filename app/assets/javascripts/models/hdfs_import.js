chorus.models.HdfsImport = chorus.models.Base.extend({
    constructorName: "HdfsImport",
    urlTemplate: "hdfs_data_sources/{{hdfsDataSourceId}}/files/{{hdfsEntryId}}/imports"
});
