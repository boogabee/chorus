describe("chorus.models.DynamicDataset", function() {
    it("should return a chorus view when the json is for a chorus view", function() {
        var model = new chorus.models.DynamicDataset(backboneFixtures.workspaceDataset.chorusView().attributes);
        expect(model).toBeA(chorus.models.ChorusView);
    });

    it("should return a workspace dataset when the json is for a workspace dataset", function() {
        var model = new chorus.models.DynamicDataset(backboneFixtures.workspaceDataset.datasetTable().attributes);
        expect(model).toBeA(chorus.models.WorkspaceDataset);
    });

    it("should return a hdfs dataset when the json is for an hdfs dataset", function () {
        var model = new chorus.models.DynamicDataset(backboneFixtures.workspaceDataset.hdfsDataset().attributes);
        expect(model).toBeA(chorus.models.HdfsDataset);
    });

    it("should return dataset otherwise", function() {
        var model = new chorus.models.DynamicDataset(backboneFixtures.dataset().attributes);
        expect(model).toBeA(chorus.models.Dataset);
    });

    it("does not need attributes", function () {
        var model = new chorus.models.DynamicDataset();
        expect(model).toBeA(chorus.models.Dataset);
    });

});