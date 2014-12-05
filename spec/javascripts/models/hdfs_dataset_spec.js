describe("chorus.models.HdfsDataset", function() {
    beforeEach(function () {
        this.model = backboneFixtures.workspaceDataset.hdfsDataset({id: null, content: ["first line", "second line"]});
    });

    describe('dataSource', function () {
        it("is not null", function () {
            expect(this.model.dataSource()).toBeA(chorus.models.HdfsDataSource);
        });
    });

    describe("#urlTemplate", function() {
        it("returns the correct create url", function () {
            expect(this.model.url({ method: 'create' })).toMatchUrl("/hdfs_datasets/");
        });

        it("returns the correct update url", function () {
            this.model.set("id", 1234);
            expect(this.model.url({ method: 'update' })).toMatchUrl("/hdfs_datasets/1234");
        });

        it("returns the show url when it is anything else", function () {
            this.model.set("id", 1234);
            expect(this.model.url({method: "read"})).toMatchUrl('/workspaces/' +  this.model.workspace().id + '/datasets/1234');
        });

        it("returns the correct delete url", function () {
            this.model.set("id", 1234);
            expect(this.model.url({ method: 'delete' })).toMatchUrl("/hdfs_datasets/1234");
        });

    });

    it("has the correct showUrl", function () {
        this.model.set({id: "123", workspace: {id: "789"}});
        expect(this.model.showUrl()).toMatchUrl("#/workspaces/789/hadoop_datasets/123");
    });

    describe("#content", function() {
        it("returns the contents", function() {
            expect(this.model.content()).toBe("first line\nsecond line");
        });
    });

    describe("#asWorkspaceDataset", function () {
        it("returns a HdfsDataset", function () {
            expect(this.model.asWorkspaceDataset()).toBeA(chorus.models.HdfsDataset);
        });
    });

    describe("#isDeletable", function () {
        it("is deletable", function () {
            expect(this.model.isDeleteable()).toBeTruthy();
        });
    });
});