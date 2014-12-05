describe("chorus.views.HdfsDatasetContentDetails", function() {
    beforeEach(function() {
        this.model = backboneFixtures.workspaceDataset.hdfsDataset({fileMask: '/my_data/*'});
        this.view = new chorus.views.HdfsDatasetContentDetails({ model: this.model });
        this.view.render();
    });

    it("has the file mask", function() {
        expect(this.view.$el).toContainTranslation('hdfs_dataset.content_details.file_mask', {fileMask: '/my_data/*'});
    });

    it("has the readonly text", function() {
        expect(this.view.$el).toContainTranslation('hdfs.read_only');
    });

    it("does not show a file mask if the model is not loaded yet", function () {
        this.model = new chorus.models.HdfsDataset();
        this.view = new chorus.views.HdfsDatasetContentDetails({ model: this.model });
        this.view.render();
        expect(this.view.$el.text().trim()).toBe(t("hdfs.read_only"));
    });
});