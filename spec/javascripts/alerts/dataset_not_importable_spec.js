describe("chorus.alerts.DatasetNotImportable", function() {
    beforeEach(function() {
        this.datasetImportability = backboneFixtures.datasetImportabilityForUnimportableDataset({
            importability: false,
            invalidColumns: ["foo", "bar"],
            supportedColumnTypes: ["supported_type1", "supported_type2"]
        });

        this.alert = new chorus.alerts.DatasetNotImportable({
            datasetImportability: this.datasetImportability
        });
        this.alert.render();
    });

    it("sets the title", function() {
        expect(this.alert.$el).toContainTranslation("dataset.import.not_importable.title");
    });

    it("renders the dataset not importable translation", function() {
        expect(this.alert.$el).toContainTranslation("dataset.import.not_importable.message", {invalidColumns: "foo\nbar"});
    });

    it("lists the invalid columns", function() {
        expect(this.alert.$('li')).toContainText("foo");
        expect(this.alert.$('li')).toContainText("bar");
    });

    it("lists the supported columns", function() {
        expect(this.alert.$('li')).toContainText("supported_type1");
        expect(this.alert.$('li')).toContainText("supported_type2");
    });

    it("shows an error icon", function() {
        expect(this.alert.$el).toHaveClass("error");
    });

    it("only has one button", function() {
        expect(this.alert.$("button.submit")).toHaveClass("hidden");
    });
});
