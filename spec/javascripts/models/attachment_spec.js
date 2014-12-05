describe("chorus.models.Attachment", function() {
    beforeEach(function() {
        var search = backboneFixtures.searchResultWithAttachmentOnWorkspaceNote();
        this.model = search.attachments().at(0);
        this.model.set({ id: "97", name: "attachmentName" });
    });

    describe("#downloadUrl", function() {
        it("with id of attachment", function() { // because search results are not consistent with "regular" attachments
            this.model.set({id: "123"});
            expect(this.model.downloadUrl()).toBe("/attachments/123/download/");
        });
    });

    describe("#iconUrl", function() {
        it("uses type for the iconUrl", function() {
            this.model.set({type: 'csv'});
            expect(this.model.iconUrl()).toBe(chorus.urlHelpers.fileIconUrl('csv'));
        });

        it("uses fileType for the iconUrl", function() {
            this.model.set({fileType: 'jpg'});
            expect(this.model.iconUrl()).toBe(chorus.urlHelpers.fileIconUrl('jpg'));
        });

        it("uses the IconUrl value if the attachment is image", function() {
            this.model.set({iconUrl: 'note/2/attachments?style=icon'});
            expect(this.model.iconUrl()).toBe('note/2/attachments?style=icon');
        });
    });

    it("returns its name", function() {
        expect(this.model.name()).toBe("attachmentName");
    });

    it("does not open its show url as an external page", function() {
        expect(this.model.useExternalLink()).toBeFalsy();
    });

    describe("#thumbnailUrl", function() {
        it("prefers fileId over id", function() { // because search results are not consistent with "regular" attachments
            this.model.set({fileId: "123"});
            expect(this.model.thumbnailUrl()).toBe("/file/123/thumbnail");
        });

        it("uses id when fileId is not present", function() {
            expect(this.model.thumbnailUrl()).toBe("/file/97/thumbnail");
        });
    });

    describe("#isImage", function() {
        beforeEach(function() {
            var search = backboneFixtures.searchResultWithAttachmentOnWorkspaceNote();
            this.model = search.attachments().at(0);
        });

        it("returns the correct value", function() {
            this.model.set({type: "IMAGE"});
            expect(this.model.isImage()).toBeTruthy();
            this.model.set({type: "OTHER"});
            expect(this.model.isImage()).toBeFalsy();
        });
    });

    describe("#showUrlTemplate", function() {
        it("shows the URL for a workspace", function() {
            var search = backboneFixtures.searchResultWithAttachmentOnWorkspaceNote();
            var model = search.attachments().at(0);
            var workspace = model.workspace();
            expect(model.showUrl()).toBe("#/workspaces/" + workspace.id);
        });

        it("shows the URL for a dataset with no workspace", function() {
            var search = backboneFixtures.searchResultWithAttachmentOnDatasetNote();
            var model = search.attachments().at(0);
            expect(model.showUrl()).toBe("#/datasets/" + model.dataset().id);
        });

        it("shows the URL for a workfile in a workspace", function() {
            var search = backboneFixtures.searchResultWithAttachmentOnWorkfileNote();
            var model = search.attachments().at(0);
            var workfile = model.workfile();
            var workspace = workfile.workspace();
            expect(model.showUrl()).toBe("#/workspaces/" + workspace.id +
                "/workfiles/" + workfile.id);
        });

        it('shows the URL for a data source', function() {
            var search = backboneFixtures.searchResultWithAttachmentOnDataSourceNote();
            var model = search.attachments().at(0);
            var dataSource = model.dataSource();
            expect(dataSource.id).toBeDefined();
            expect(model.showUrl()).toBe(dataSource.showUrl());
        });

        it("shows the URL for an hdfsFile", function() {
            var search = backboneFixtures.searchResultWithAttachmentOnHdfsNote();
            var model = search.attachments().at(0);
            var hdfs = model.hdfsFile();
            var hadoop = model.hdfsDataSource();
            expect(model.showUrl()).toBe("#/hdfs_data_sources/" + hadoop.id + "/browseFile/" + hdfs.id);
        });
    });

    describe("workspace", function() {
        beforeEach(function() {
            var search = backboneFixtures.searchResultWithAttachmentOnWorkspaceNote();
            this.model = search.attachments().at(0);
        });

        it("returns the workspace", function() {
            this.workspace = this.model.workspace();
            expect(this.workspace.get('name')).toBe(this.model.get('workspace').name);
            expect(this.workspace.get('id')).toBe(this.model.get('workspace').id);
        });

        it("returns falsy when there is no workspace", function() {
            this.model.unset('workspace');
            expect(this.model.workspace()).toBeFalsy();
        });

        it("returns falsy when workspace is empty", function() {
            this.model.set({workspace: {}});
            expect(this.model.workspace()).toBeFalsy();
        });

        it("memoizes", function() {
            expect(this.model.workspace()).toBe(this.model.workspace());
        });
    });

    describe("workfile", function() {
        beforeEach(function() {
            var search = backboneFixtures.searchResultWithAttachmentOnWorkfileNote();
            this.model = search.attachments().at(0);
        });

        it("returns the workfile", function() {
            var workfile = this.model.workfile();

            expect(workfile.get('name')).toBe(this.model.get('workfile').name);
            expect(workfile.get('id')).toBe(this.model.get('workfile').id);
        });

        it("returns falsy when there is no workfile", function() {
            this.model.unset('workfile');
            expect(this.model.workfile()).toBeFalsy();
        });

        it("memoizes", function() {
            expect(this.model.workfile()).toBe(this.model.workfile());
        });
    });

    describe("hdfs", function() {
        beforeEach(function() {
            var search = backboneFixtures.searchResultWithAttachmentOnHdfsNote();
            this.model = search.attachments().at(0);
        });

        it("returns the hdfsFile", function() {
            this.hdfsFile = this.model.hdfsFile();
            expect(this.hdfsFile.get('name')).toBe(this.model.get('hdfsEntry').name);
            expect(this.hdfsFile.get('id')).toBe(this.model.get('hdfsEntry').id);
        });

        it("returns falsy when there is no hdfsFile", function() {
            this.model.unset('hdfsEntry');
            expect(this.model.hdfsFile()).toBeFalsy();
        });

        it("memoizes", function() {
            expect(this.model.hdfsFile()).toBe(this.model.hdfsFile());
        });
    });

    describe('data source', function() {
        beforeEach(function() {
            var search = backboneFixtures.searchResultWithAttachmentOnDataSourceNote();
            this.model = search.attachments().at(0);
        });

        it("returns the data source", function() {
            this.dataSource = this.model.dataSource();
            expect(this.dataSource.get('name')).toBe(this.model.get('dataSource').name);
            expect(this.dataSource.get('id')).toBe(this.model.get('dataSource').id);
        });

        it("dynamically assigns the data source type", function() {
            expect(this.model.dataSource()).toBeA(chorus.models.GpdbDataSource);
            var search = backboneFixtures.searchResultWithAttachmentOnHadoopNote();
            var model = search.attachments().at(0);
            expect(model.dataSource()).toBeA(chorus.models.HdfsDataSource);
        });

        it("returns falsy when there is no data source", function() {
            this.model.unset('dataSource');
            expect(this.model.dataSource()).toBeFalsy();
        });

        it("memoizes", function() {
            expect(this.model.dataSource()).toBe(this.model.dataSource());
        });
    });

    describe("dataset", function() {
        beforeEach(function() {
            var search = backboneFixtures.searchResultWithAttachmentOnDatasetNote();
            this.model = search.attachments().at(0);
        });

        it("returns a Database Object", function() {
            this.dataset = this.model.dataset();
            expect(this.dataset).toBeA(chorus.models.Dataset);
            expect(this.dataset.get('objectName')).toBe(this.model.get('dataset').objectName);
            expect(this.dataset.get('id')).toBe(this.model.get('dataset').id);
        });

        it("returns falsy when there is no dataset", function() {
            this.model.unset('dataset');
            expect(this.model.dataset()).toBeFalsy();
        });

        it("memoizes", function() {
            expect(this.model.dataset()).toBe(this.model.dataset());
        });

        context("ChorusView", function() {
            beforeEach(function() {
                this.model.get('dataset')['entitySubtype'] = "CHORUS_VIEW";
                this.dataset = this.model.dataset();
            });

            it("returns a ChorusView Object", function() {
                expect(this.dataset).toBeA(chorus.models.ChorusView);
                expect(this.dataset.get('objectName')).toBe(this.model.get('dataset').objectName);
                expect(this.dataset.get('id')).toBe(this.model.get('dataset').id);
            });

            it("return a url appropriate for a ChorusView", function() {
                expect(this.dataset.showUrl()).toContain("chorus_views");
            });
        });
    });
});