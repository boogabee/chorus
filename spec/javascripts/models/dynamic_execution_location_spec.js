describe("chorus.models.DynamicExecutionLocation", function() {
    it("returns a Database when the json is for a database", function() {
        var attrs = backboneFixtures.database().attributes;
        var model = new chorus.models.DynamicExecutionLocation(attrs);
        expect(model).toBeA(chorus.models.Database);
    });

    it("returns an HdfsDataSource when the json is for an hdfs data source", function() {
        var model = new chorus.models.DynamicExecutionLocation(backboneFixtures.hdfsDataSource().attributes);
        expect(model).toBeA(chorus.models.HdfsDataSource);
    });
    
    it("returns an OracleDataSource when the json id for an oracle data source", function() {
        var model = new chorus.models.DynamicExecutionLocation(backboneFixtures.oracleDataSource().attributes);
        expect(model).toBeA(chorus.models.OracleDataSource);
    });
    
    it("returns a JdbcDataSource when the json id for a jdbc data source", function() {
        var model = new chorus.models.DynamicExecutionLocation(backboneFixtures.jdbcDataSource().attributes);
        expect(model).toBeA(chorus.models.JdbcDataSource);
    });
});
