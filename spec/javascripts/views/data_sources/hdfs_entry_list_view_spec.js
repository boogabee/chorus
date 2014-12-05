describe("chorus.views.HdfsEntryList", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.HdfsEntrySet([
            backboneFixtures.hdfsDir({count: 1}),
            backboneFixtures.hdfsFile(),
            backboneFixtures.hdfsFile(),
            backboneFixtures.hdfsDir({count: -1})
        ], {hdfsDataSource: {id: "1234"}, path: "/abc" });

        this.view = new chorus.views.HdfsEntryList({collection: this.collection});
    });

    it("uses a loading section", function() {
        this.view.render();
        expect(this.view.$(".loading_section")).toExist();
    });

    describe("checkability with uncheckable models", function() {
        beforeEach(function() {
            this.files = [
                backboneFixtures.hdfsFile(),
                backboneFixtures.hdfsFile(),
                backboneFixtures.hdfsFile()
            ];

            this.directories = [
                backboneFixtures.hdfsDir({count: 1}),
                backboneFixtures.hdfsDir({count: -1})
            ];

            this.collection = new chorus.collections.HdfsEntrySet(this.files,
                { hdfsDataSource: {id: "1234"}, path: "/abc" }
            );

            this.view = new chorus.views.HdfsEntryList({collection: this.collection});

            spyOn(this.view.selectedModels, "add").andCallThrough();

            this.view.render();
        });

        itBehavesLike.PageItemList();
    });

    describe("when the entries have loaded", function() {
        beforeEach(function() {
            this.collection.loaded = true;
            this.view.render();
        });

        it("renders the name for each item", function() {
            expect(this.view.$("li:eq(0) .name")).toContainText(this.collection.at(0).get("name"));
            expect(this.view.$("li:eq(1) .name")).toContainText(this.collection.at(1).get("name"));
        });

        it("renders the size for the file", function() {
            expect(this.view.$("li:eq(1) .description")).toContainText(I18n.toHumanSize(this.collection.at(1).get("size")));
        });

        it("renders the icon for each item", function() {
            expect(this.view.$("li:eq(0) img").attr("src")).toBe("/images/data_sources/hadoop_directory_large.png");
            expect(this.view.$("li:eq(1) img").attr("src")).toBe(chorus.urlHelpers.fileIconUrl(_.last(this.collection.at(1).get("name").split("."))));
        });

        it("links the directory name to that browse page", function() {
            expect(this.view.$("li:eq(0) a.name").attr("href")).toBe("#/hdfs_data_sources/1234/browse/" + this.collection.at(0).id);
        });

        it("shows 'Directory - x files' in the subtitle line for the directory", function() {
            expect(this.view.$("li:eq(0) .description")).toContainTranslation("hdfs.directory_files", {count: this.collection.at(0).get("count")});
        });

        it('doesnt show a checkbox', function(){
            expect(this.view.$("li:eq(0) input[type=checkbox]")).not.toExist();
        });

        it("displays a not permitted message if the user doesnt have access", function() {
            expect(this.view.$("li:last .description")).toContainTranslation("hdfs.directory_files.no_permission");
        });

        describe("when browsing the root directory", function() {
            beforeEach(function() {
                this.collection.attributes.path = "/";
                this.view.render();
            });

            it("links the directory name to that browse page", function() {
                expect(this.view.$("li:eq(0) a.name").attr("href")).toBe("#/hdfs_data_sources/1234/browse/" + this.collection.at(0).id);
            });
        });
    });
});
