chorus.models.DynamicDataSource = function(dataSourceJSON) {
    if (!chorus.models[chorus.models.DynamicDataSource.typeMap[dataSourceJSON.entityType]]) {
        window.console.error("Unknown Data Source Type!", dataSourceJSON.entityType, dataSourceJSON);
    }

    return new chorus.models[chorus.models.DynamicDataSource.typeMap[dataSourceJSON.entityType]](dataSourceJSON);
};

chorus.models.DynamicDataSource.typeMap = {
    data_source: 'GpdbDataSource',
    gpdb_data_source: 'GpdbDataSource',
    hdfs_data_source: 'HdfsDataSource',
    gnip_data_source: 'GnipDataSource',
    oracle_data_source: 'OracleDataSource',
    pg_data_source: 'PgDataSource',
    jdbc_data_source: 'JdbcDataSource'
};
