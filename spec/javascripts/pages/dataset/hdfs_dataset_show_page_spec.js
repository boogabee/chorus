describe("chorus.pages.HdfsDatasetShowPage", function () {
    beforeEach(function () {
        this.dataset = backboneFixtures.workspaceDataset.hdfsDataset();
        this.dataset.set("content", ["hello, from, hadoop"]);
        this.workspace = this.dataset.workspace();
        this.datasetId = this.dataset.get('id');

        this.page = new chorus.pages.HdfsDatasetShowPage(this.workspace.get("id"), this.datasetId);
    });

    describe("#initialize", function () {
        it("constructs an hdfs dataset with the right id", function () {
            expect(this.page.model).toBeA(chorus.models.HdfsDataset);
            expect(this.page.model.get("id")).toBe(this.datasetId);
        });

        it("has a helpId", function () {
            expect(this.page.helpId).toBe("dataset");
        });
    });

    it("shows only a loading spinner initially", function () {
        expect(this.page.mainContent).toBeA(chorus.views.LoadingSection);
        expect(this.page.sidebar).toBeUndefined();
    });

    describe("when the workspace and dataset fetches complete", function () {
        beforeEach(function () {
            this.server.completeFetchFor(this.workspace);
            this.server.completeFetchFor(this.dataset);
        });

        it("has the subnav focused on data", function () {
            expect(this.page.subNav).toBeA(chorus.views.SubNav);
            expect(this.page.subNav.$(".datasets")).toHaveClass("selected");
        });


        it("has a titlebar", function () {
            expect(this.page.$(".page_sub_header")).toContainText(this.workspace.name());
        });

        it("sets up the main content", function () {
            expect(this.page.mainContent).toBeA(chorus.views.MainContentView);
            expect(this.page.sidebar).not.toBeUndefined();
        });

        it("shows the dataset content", function () {
            expect(this.page.mainContent.content).toBeA(chorus.views.ReadOnlyTextContent);
            expect(this.page.mainContent.content.model.get('content')).toEqual(this.dataset.get("content"));
        });

        it("shows the DatasetShowContentHeader", function () {
            expect(this.page.mainContent.contentHeader).toBeA(chorus.views.DatasetShowContentHeader);
        });

        it("shows the DatasetShowContentDetails", function () {
            expect(this.page.mainContent.contentDetails).toBeA(chorus.views.HdfsDatasetContentDetails);
        });

        it("sets up the sidebar", function () {
            expect(this.page.sidebar).toBeA(chorus.views.DatasetSidebar);
        });

        it("sets up sidebar activities & statistics", function () {
            expect(this.page.$('.activity_list')).toExist();
            expect(this.page.$('.dataset_statistics')).toExist();
        });

    });

    describe("when the hdfs dataset is invalidated", function () {
        beforeEach(function () {
            this.server.reset();
            this.page.model.trigger("invalidated");
        });

        it("the hdfs dataset should refetch", function () {
            expect(this.page.model).toHaveBeenFetched();
        });
    });
});
