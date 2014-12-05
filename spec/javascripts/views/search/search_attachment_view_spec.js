describe("chorus.views.SearchAttachment", function() {
    beforeEach(function() {
        var search = backboneFixtures.searchResultWithAttachmentOnWorkspaceNote();
        this.result = search.attachments().at(0);
        this.view = new chorus.views.SearchAttachment({model: this.result});
        this.view.render();
    });

    it("shows the thumbnail for an image", function() {
        expect(this.view.$("img.icon").attr("src")).toBe(this.result.iconUrl());
    });

    it("shows the iconUrl for a non-image", function() {
        this.result.set({fileType: "OTHER"});
        expect(this.view.$("img.icon").attr("src")).toBe(this.result.iconUrl());
    });

    it("has a link to the download for the attachment", function() {
        expect(this.view.$('a.name').attr('href')).toBe(this.result.downloadUrl());
    });

    context("with tabular data", function() {
        beforeEach(function() {
            var search = backboneFixtures.searchResultWithAttachmentOnDatasetNote();
            this.result = search.attachments().at(0);
            this.view = new chorus.views.SearchAttachment({model: this.result});
            this.view.render();
        });

        it("shows the tabular data set", function() {
            expect(
                this.view.$(".description .found_in").html()).toContainTranslation(
                "attachment.found_in.dataset_not_in_workspace",
                {
                    datasetLink: '<a href="#/datasets/' + this.result.dataset().id  + '">searchquery_table</a>'
                }
            );
        });
    });

    context("with workfile in a workspace", function() {
        beforeEach(function() {
            var search = backboneFixtures.searchResultWithAttachmentOnWorkfileNote();
            this.result = search.attachments().at(0);
            this.view = new chorus.views.SearchAttachment({model: this.result});
            this.view.render();
        });

        it("shows the workfile set", function() {
            var workfile = this.result.workfile();
            var workspace = workfile.workspace();

            var workspaceUrl = "#/workspaces/"+workspace.id;
            var workfileUrl = workspaceUrl+ "/workfiles/"+workfile.id;

            expect(
                this.view.$(".description .found_in").html()).toContainTranslation(
                "attachment.found_in.workfile_in_workspace",
                {
                    workfileLink: '<a href="'+workfileUrl+'">'+workfile.name()+'</a>',
                    workspaceLink: '<a href="'+workspaceUrl+'">'+workspace.name()+'</a>'
                }
            );
        });
    });

    context("with file in a hdfs", function() {
        beforeEach(function() {
            var search = backboneFixtures.searchResultWithAttachmentOnHdfsNote();
            this.result = search.attachments().at(0);
            this.view = new chorus.views.SearchAttachment({model: this.result});
            this.view.render();
        });

        it("shows the file", function() {
            var hdfs = this.result.hdfsFile();
            var hdfsDataSource = this.result.hdfsDataSource();
            expect(
                this.view.$(".description .found_in").html()).toContainTranslation(
                "attachment.found_in.file_in_hdfs",
                {
                    hdfsFileLink: '<a href="#/hdfs_data_sources/' + hdfsDataSource.id +  '/browseFile/' + hdfs.id  +'">'+hdfs.name()+'</a>'
                }
            );
        });
    });

    context("with workspace", function() {
        beforeEach(function() {
            var search = backboneFixtures.searchResultWithAttachmentOnWorkspaceNote();
            this.result = search.attachments().at(0);
            this.view = new chorus.views.SearchAttachment({model: this.result});
            this.view.render();
        });

        it("shows the file", function() {
            var workspace = this.result.workspace();

            expect(
                this.view.$(".description .found_in").html()).toContainTranslation(
                "attachment.found_in.workspace",
                {
                    workspaceLink: '<a href="#/workspaces/'+workspace.id+'">'+workspace.name()+'</a>'
                }
            );
        });
    });

    context('with data source', function() {
        beforeEach(function() {
            var search = backboneFixtures.searchResultWithAttachmentOnDataSourceNote();
            this.result = search.attachments().at(0);
            this.view = new chorus.views.SearchAttachment({model: this.result});
            this.view.render();
        });

        it("shows the file", function() {
            var dataSource = this.result.dataSource();
            expect(
                this.view.$(".description .found_in").html()).toContainTranslation(
                "attachment.found_in.data_source",
                {
                    dataSourceLink: '<a href="#/data_sources/'+dataSource.id+'/databases">'+dataSource.name()+'</a>'
                }
            );
        });
    });

    it("doesn't escape the links", function() {
        expect(this.view.$(".description .found_in").html()).toContain("<");
        expect(this.view.$(".description .found_in").html()).toContain(">");
    });

    it("shows matching name", function() {
        expect(this.view.$(".name").html()).toContain("<em>searchquery</em>_<em>workspace<\/em>");
    });
});
