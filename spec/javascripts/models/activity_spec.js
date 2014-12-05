describe("chorus.models.Activity", function() {
    beforeEach(function() {
        this.model = backboneFixtures.activity.dataSourceCreated();
    });

    describe("model associations", function() {
        var activity;

        describe("#newOwner", function() {
            it("returns a user with the newOwner data", function() {
                activity = backboneFixtures.activity.dataSourceChangedOwner({
                    actor: { id: 5 },
                    dataSource: { id: 6 },
                    newOwner: { id: 7 }
                });

                var newOwner = activity.newOwner();
                expect(newOwner).toBeA(chorus.models.User);
                expect(newOwner.id).toBe(7);
            });
        });

        describe("#actor", function() {
            it("returns a user with the right data", function() {
                activity = backboneFixtures.activity.dataSourceChangedOwner({
                    actor: { id: 5 },
                    dataSource: { id: 6 },
                    newOwner: { id: 7 }
                });

                var actor = activity.actor();
                expect(actor).toBeA(chorus.models.User);
                expect(actor.id).toBe(5);
            });
        });

        describe("#promoter", function() {
            it("returns a user with the right data", function() {
                activity = backboneFixtures.activity.insightOnGreenplumDataSource({
                    promotedBy: { id: 5 },
                    dataSource: { id: 6 }
                });

                var promoter = activity.promoter();
                expect(promoter).toBeA(chorus.models.User);
                expect(promoter.id).toBe(5);
            });
            it("returns null if the note is not an insight", function() {
                activity = backboneFixtures.activity.dataSourceChangedOwner();
                var promoter = activity.promoter();
                expect(promoter).toBeNull();
            });
        });

        describe("#member", function() {
            it("returns a user with the right data", function() {
                activity = backboneFixtures.activity.membersAdded({
                    actor: { id: 5 },
                    member: { id: 6 }
                });

                var member = activity.member();
                expect(member).toBeA(chorus.models.User);
                expect(member.id).toBe(6);
            });
        });

        describe("#hdfsDataSource", function() {
            it("returns a hadoop data source with the right data", function() {
                activity = backboneFixtures.activity.hdfsDataSourceCreated({
                    hdfsDataSource: { id: 8 }
                });

                var hdfsDataSource = activity.hdfsDataSource();
                expect(hdfsDataSource).toBeA(chorus.models.HdfsDataSource);
                expect(hdfsDataSource.id).toBe(8);
            });
        });

        describe("#gnipDataSource", function() {
            it("returns a gnip data source with the right data", function() {
                activity = backboneFixtures.activity.gnipDataSourceCreated({
                    gnipDataSource: { id: 8 }
                });

                var gnipDataSource = activity.gnipDataSource();
                expect(gnipDataSource).toBeA(chorus.models.GnipDataSource);
                expect(gnipDataSource.id).toBe(8);
            });
        });

        describe("#gpdbDataSource", function() {
            it("returns a gpdb data source with the right data", function() {
                activity = backboneFixtures.activity.dataSourceChangedOwner({
                    actor: { id: 5 },
                    dataSource: { id: 6 },
                    newOwner: { id: 7 }
                });

                var dataSource = activity.dataSource();
                expect(dataSource).toBeA(chorus.models.DataSource);
                expect(dataSource.id).toBe(6);
            });
        });

        describe("#workspace", function() {
            it("returns a Workspace with the right data", function() {
                activity = backboneFixtures.activity.sourceTableCreated({
                    dataset: { id: 9 },
                    workspace: {id: 10}
                });

                var workspace = activity.workspace();
                expect(workspace).toBeA(chorus.models.Workspace);
                expect(workspace.id).toBe(10);
            });
        });

        describe("#schema", function() {
            it("returns a Schema with the right data", function() {
                activity = backboneFixtures.activity.schemaImportCreated({
                });

                var schema = activity.schema();
                expect(schema).toBeA(chorus.models.Schema);
                expect(schema.id).toBe(activity.get('schema').id);
            });
        });

        describe("#workfile", function() {
            it("returns a workfile with the right data", function() {
                activity = backboneFixtures.activity.workfileCreated({
                    workfile: {id: 11}
                });

                var workfile = activity.workfile();
                expect(workfile).toBeA(chorus.models.Workfile);
                expect(workfile.id).toBe(11);
            });
        });

        describe("#dataset", function() {
            var dataset;

            beforeEach(function() {
                activity = backboneFixtures.activity.sourceTableCreated({
                    dataset: { id: 9 },
                    workspace: {id: 10}
                });

                dataset = activity.dataset();
            });

            it("returns a WorkspaceDataset with the right data", function() {
                expect(dataset).toBeA(chorus.models.WorkspaceDataset);
                expect(dataset.id).toBe(9);
            });

            it("adds the workspace data to the dataset", function() {
                expect(dataset.get("workspace").id).toBe(10);
            });

            context("when the dataset is an HDFS Dataset", function () {
                beforeEach(function () {
                    activity = backboneFixtures.activity.sourceTableCreated({
                        dataset: { id: 9, entitySubtype: "HDFS" },
                        workspace: {id: 10}
                    });

                    dataset = activity.dataset();
                });

                it("returns an HDFS Dataset with the right data", function() {
                    expect(dataset).toBeA(chorus.models.HdfsDataset);
                    expect(dataset.id).toBe(9);
                });
            });
        });

        describe("#sourceDataset", function() {
            var dataset;

            beforeEach(function() {
                activity = backboneFixtures.activity.workspaceImportSuccess({
                    sourceDataset: { id: 9, associatedWorkspaces: [{id: 10}]}
                });

                dataset = activity.importSource();
            });

            it("returns a WorkspaceDataset with the right data", function() {
                expect(dataset).toBeA(chorus.models.WorkspaceDataset);
                expect(dataset.id).toBe(9);
            });

            it("adds the workspace data to the sourceDataset", function() {
                expect(dataset.get("associatedWorkspaces")[0].id).toBe(10);
            });
        });

        describe("#newUser", function() {
            it("returns a new user with the right data", function() {
                activity = backboneFixtures.activity.userCreated({
                    newUser: {id: 12}
                });

                var user = activity.newUser();
                expect(user).toBeA(chorus.models.User);
                expect(user.id).toBe(12);
            });
        });

        describe("#noteObject", function() {
            context("for a NoteOnDataSource", function() {
                it("returns a gpdbDataSource with the right data", function() {
                    activity = backboneFixtures.activity.noteOnGreenplumDataSource({
                        dataSource: { id: 13 }
                    });

                    var dataSource = activity.dataSource();
                    expect(dataSource).toBeA(chorus.models.GpdbDataSource);
                    expect(dataSource.id).toBe(13);
                });
            });

            context("for a NoteOnGnipDataSource", function() {
                it("returns a gnip data source with the right data", function() {
                    activity = backboneFixtures.activity.noteOnGnipDataSourceCreated({
                        gnipDataSource: { id: 13 }
                    });

                    var gnipDataSource = activity.gnipDataSource();
                    expect(gnipDataSource).toBeA(chorus.models.GnipDataSource);
                    expect(gnipDataSource.id).toBe(13);
                });
            });

            context("for a NoteOnHdfsFile", function() {
                it("returns a hdfsFile with the right data", function() {
                    activity = backboneFixtures.activity.noteOnHdfsFileCreated({
                        hdfsFile: { id: 2345, name: "path.txt", hdfsDataSource: {id: 331} }
                    });
                    var hdfsFile = activity.noteObject();
                    expect(hdfsFile).toBeA(chorus.models.HdfsEntry);
                    expect(hdfsFile.get("name")).toBe("path.txt");
                    expect(hdfsFile.get("hdfsDataSource").id).toBe(331);
                });
            });

            context("for a NoteOnWorkspace", function() {
                it("returns a workspace with the right data", function() {
                    activity = backboneFixtures.activity.noteOnWorkspaceCreated({
                        workspace: { id: 123 }
                    });
                    var workspace = activity.noteObject();
                    expect(workspace).toBeA(chorus.models.Workspace);
                    expect(workspace.get("id")).toBe(123);
                });
            });

            context("for a NoteOnDataset", function() {
                it("returns a dataset with the right data", function() {
                    activity = backboneFixtures.activity.noteOnDatasetCreated({
                        dataset: { id: 123 }
                    });
                    var dataset = activity.noteObject();
                    expect(dataset).toBeA(chorus.models.Dataset);
                    expect(dataset.get("id")).toBe(123);
                });
            });

            context("for a NoteOnWorkspaceDataset", function() {
                it("returns a workspace dataset with the right data", function() {
                    activity = backboneFixtures.activity.noteOnWorkspaceDatasetCreated({
                        dataset: { id: 123 }
                    });
                    var ws_dataset = activity.noteObject();
                    expect(ws_dataset).toBeA(chorus.models.WorkspaceDataset);
                    expect(ws_dataset.get("id")).toBe(123);
                });
            });

            context("for a NoteOnWorkfile", function() {
                it("returns a workfile with the right data", function() {
                    activity = backboneFixtures.activity.noteOnWorkfileCreated({
                        workfile: { id: 123 }
                    });
                    var workfile = activity.noteObject();
                    expect(workfile).toBeA(chorus.models.Workfile);
                    expect(workfile.get("id")).toBe(123);
                });
            });
        });

        describe("#hdfsEntry", function() {
            it("returns hdfs entry with the right data", function() {
                activity = backboneFixtures.activity.hdfsFileExtTableCreated({
                    hdfsEntry: {
                        id: 1234,
                        hdfsDataSource: {id: 1},
                        name: "file.csv"
                    }
                });

                var hdfsEntry = activity.hdfsEntry();
                expect(hdfsEntry).toBeA(chorus.models.HdfsEntry);
                expect(hdfsEntry.name()).toBe("file.csv");
                expect(hdfsEntry.get("hdfsDataSource").id).toBe(1);
                expect(hdfsEntry.get("id")).toBe(1234);
            });
        });

        describe("#hdfsDataset", function () {
            it("returns hdfs dataset with the right data", function() {
                activity = backboneFixtures.activity.hdfsDatasetExtTableCreated();

                var hdfsDataset = activity.hdfsDataset();
                expect(hdfsDataset).toBeA(chorus.models.HdfsDataset);
            });
        });
    });

    describe("#isUserGenerated", function() {
        it("returns true for notes", function() {
            expect(backboneFixtures.activity.noteOnGreenplumDataSource().isUserGenerated()).toBeTruthy();
        });

        it("returns true for 'INSIGHT_CREATED' activities", function() {
            expect(backboneFixtures.activity.insightOnGreenplumDataSource().isUserGenerated()).toBeTruthy();
        });

        it("returns false for other activities", function() {
            expect(backboneFixtures.activity.membersAdded().isUserGenerated()).toBeFalsy();
        });

        it("returns true for sub-comments", function() {
            expect(backboneFixtures.comment().isUserGenerated()).toBeTruthy();
        });
    });

    describe("#hasCommitMessage", function() {
        it("returns true for activity where action is Workfile_upgrade_version and commit message is not empty", function() {
            expect(backboneFixtures.activity.workfileUpgradedVersion().hasCommitMessage()).toBeTruthy();
        });

        it("returns true for activity where action is work flow upgraded version and commit message is not empty", function() {
            expect(backboneFixtures.activity.workFlowUpgradedVersion().hasCommitMessage()).toBeTruthy();
        });

        it("returns true for activity where action is WorkfileCreated with commit message", function() {
            expect(backboneFixtures.activity.workfileCreated().hasCommitMessage()).toBeTruthy();
        });

        it("returns false for other activities", function() {
            expect(backboneFixtures.activity.membersAdded().hasCommitMessage()).toBeFalsy();
        });

        it("returns false for activity where action is Workfile_upgrade_version and commit message is empty", function() {
            expect(backboneFixtures.activity.workfileUpgradedVersion({commitMessage: ""}).hasCommitMessage()).toBeFalsy();
        });
    });

    describe("#isFailure", function() {
        it("returns true for IMPORT_FAILED", function() {
            expect(backboneFixtures.activity.fileImportFailed().isFailure()).toBeTruthy();
            expect(backboneFixtures.activity.workspaceImportFailed().isFailure()).toBeTruthy();
            expect(backboneFixtures.activity.schemaImportFailed().isFailure()).toBeTruthy();
            expect(backboneFixtures.activity.gnipStreamImportFailed().isFailure()).toBeTruthy();
        });

        it("returns false for other activities", function() {
            expect(backboneFixtures.activity.userCreated().isFailure()).toBeFalsy();
        });
    });

    describe("#isSuccessfulImport", function() {
        it("returns true for IMPORT SUCCESS", function() {
            expect(backboneFixtures.activity.fileImportSuccess().isSuccessfulImport()).toBeTruthy();
            expect(backboneFixtures.activity.workspaceImportSuccess().isSuccessfulImport()).toBeTruthy();
            expect(backboneFixtures.activity.schemaImportSuccess().isSuccessfulImport()).toBeTruthy();
            expect(backboneFixtures.activity.gnipStreamImportSuccess().isSuccessfulImport()).toBeTruthy();
        });

        it("returns false for other activities", function() {
            expect(backboneFixtures.activity.fileImportFailed().isSuccessfulImport()).toBeFalsy();
            expect(backboneFixtures.activity.workspaceImportFailed().isSuccessfulImport()).toBeFalsy();
        });
    });

    describe("#isOwner", function() {

        it("returns true for notes is current user is the owner of note", function() {
            this.activity2 = backboneFixtures.activity.noteOnGreenplumDataSource({
                dataSource: { id: 13 },
                actor: {id: chorus.session.user().id}

            });
            expect(this.activity2.isOwner()).toBeTruthy();
        });
        it("returns false for notes is current user is not the owner of note", function() {
            this.activity2 = backboneFixtures.activity.noteOnGreenplumDataSource({
                dataSource: { id: 13 },
                actor: {id: 1}

            });
            expect(this.activity2.isOwner()).toBeFalsy();
        });

    });

    describe("#toNote", function() {
        beforeEach(function() {
            this.model = backboneFixtures.activity.noteOnGreenplumDataSource({
                id: 101
            });

            this.model.collection = new chorus.collections.ActivitySet([]);
        });

        it("returns a note with the right attributes", function() {
            var note = this.model.toNote();
            expect(note).toBeA(chorus.models.Note);
            expect(note.get("id")).toBe(101);
            expect(note.get("body")).toBe(this.model.get("body"));
        });
    });

    describe("#promoteToInsight", function() {
        beforeEach(function() {
            this.success = jasmine.createSpy("success");
            this.model.collection = new chorus.collections.ActivitySet([]);
            this.model.promoteToInsight({ success: this.success });
        });

        it("posts to the comment insight url with the correct parameters", function() {
            expect(this.server.lastCreate().url).toBe("/insights");
            expect(this.server.lastCreate().json()['note']['note_id']).toBe(this.model.id);
        });

        it("calls the success function", function() {
            this.server.lastCreate().succeed();
            expect(this.success).toHaveBeenCalledWith(this.model);
        });
    });

    describe("#demoteFromInsight", function() {
        beforeEach(function() {
            this.model = backboneFixtures.activity.insightOnGreenplumDataSource();
            this.model.collection = new chorus.collections.ActivitySet([]);
            spyOn(this.model.collection, 'fetch');
            this.model.demoteFromInsight();
        });

        it("posts to the comment insight url with the correct parameters", function() {
            expect(this.server.lastDestroy().url).toBe("/insights/" + this.model.id);
        });

        it("unsets 'isinsight' on the activity", function() {
            this.server.lastDestroy().succeed();
            expect(this.model.get('isInsight')).toBeFalsy();
        });
    });

    describe("#canBeDemotedBy", function () {
        context("for a workspace insight", function () {
            beforeEach(function () {
                this.model = backboneFixtures.activity.insightOnWorkspace();
            });

            it("returns true for the promoter, workspace owner, or admin", function () {
                expect(this.model.canBeDemotedBy(this.model.promoter())).toBeTruthy();
                expect(this.model.canBeDemotedBy(this.model.workspace().owner())).toBeTruthy();
                expect(this.model.canBeDemotedBy(backboneFixtures.user({admin: true}))).toBeTruthy();
                expect(this.model.canBeDemotedBy(backboneFixtures.user())).toBeFalsy();
            });
        });

        context("for an insight without a workspace", function () {
            beforeEach(function () {
                this.model = backboneFixtures.activity.insightOnGreenplumDataSource();
            });

            it("returns true for the promoter or admin", function () {
                expect(this.model.canBeDemotedBy(this.model.promoter())).toBeTruthy();
                expect(this.model.canBeDemotedBy(backboneFixtures.user({admin: true}))).toBeTruthy();
                expect(this.model.canBeDemotedBy(backboneFixtures.user())).toBeFalsy();
            });
        });

        context("for a non-insight", function () {
            beforeEach(function () {
                this.model = backboneFixtures.activity.noteOnGreenplumDataSource();
            });

            it("returns false", function () {
                expect(this.model.canBeDemotedBy(backboneFixtures.user({admin: true}))).toBeFalsy();
                expect(this.model.canBeDemotedBy(backboneFixtures.user())).toBeFalsy();
            });
        });
    });
    describe("#publish", function() {
        it("posts to the comment insight url with the publish action", function() {
            this.model.publish();
            expect(this.server.lastCreate().url).toBe("/insights/publish");
        });
    });

    describe("#unpublish", function() {
        it("posts to the comment insight url with the unpublish action", function() {
            this.model.unpublish();
            expect(this.server.lastCreate().url).toBe("/insights/unpublish");
        });
    });

    describe("#isNote", function() {
        it("returns true for notes", function() {
            this.model.set({ action: "NOTE" });
            expect(this.model.isNote()).toBeTruthy();
        });

        it("returns false for non-notes", function() {
            this.model.set({ type: "WorkspaceMakePublic" });
            expect(this.model.isNote()).toBeFalsy();
        });
    });

    describe("#canBePromotedToInsight", function() {
        it("returns true if it is a note but not an insight", function() {
            this.model.set({ action: "NOTE", isInsight: false });
            expect(this.model.canBePromotedToInsight()).toBeTruthy();
        });

        it("returns false for insights", function() {
            this.model.set({ action: "NOTE", isInsight: true });
            expect(this.model.canBePromotedToInsight()).toBeFalsy();
        });

        it("returns false for non-notes", function() {
            this.model.set({ type: "WorkspaceMakePublic" });
            expect(this.model.canBePromotedToInsight()).toBeFalsy();
        });
    });

    describe("#isInsight", function() {
        it("returns true for insights", function() {
            this.model.set({ isInsight: true });
            expect(this.model.isInsight()).toBeTruthy();
        });

        it("returns false for non-insights", function() {
            this.model.set({ type: "WorkspaceMakePublic" });
            expect(this.model.isInsight()).toBeFalsy();
        });
    });

    describe("#isPublished", function() {
        it("returns true for published insights", function() {
            this.model.set({ isInsight: true, isPublished: true });
            expect(this.model.isPublished()).toBeTruthy();
        });

        it("returns false for non-insights", function() {
            this.model.set({ type: "WorkspaceMakePublic" });
            expect(this.model.isPublished()).toBeFalsy();
        });

        it("returns false for non-published insights", function() {
            this.model.set({ type: "WorkspaceMakePublic", isInsight: true, isPublished: false });
            expect(this.model.isPublished()).toBeFalsy();
        });
    });

    describe("#isSubComment", function() {
        it("returns true for sub-comments", function() {
            this.model.set({ action: "SUB_COMMENT" });
            expect(this.model.isSubComment()).toBeTruthy();
        });

        it("returns false for anything else", function() {
            this.model.set({ type: "NOTE" });
            expect(this.model.isSubComment()).toBeFalsy();
        });
    });

    describe("#isPublished", function() {
        it("returns true for insights that are published", function() {
            this.model.set({isPublished: true});
            expect(this.model.isPublished()).toBeTruthy();
        });

        it("returns false for insights that are not published", function() {
            this.model.set({isPublished: false});
            expect(this.model.isPublished()).toBeFalsy();
        });

        it("returns false for non-insights", function() {
            this.model.set({isPublished: undefined});
            expect(this.model.isPublished()).toBeFalsy();
        });
    });

    describe("#author", function() {
        context("when author information is present", function() {
            beforeEach(function() {
                this.model = backboneFixtures.comment();
            });
            it("creates a user", function() {
                expect(this.model.author()).toBeA(chorus.models.User);
            });

            it("returns the same data source when called multiple times", function() {
                expect(this.model.author()).toBe(this.model.author());
            });
        });

        context("when actor information is present", function () {
            beforeEach(function() {
                this.model = backboneFixtures.activity.noteOnWorkspaceCreated();
            });
            it("creates a user", function() {
                expect(this.model.author()).toBeA(chorus.models.User);
            });

            it("returns the same data source when called multiple times", function() {
                expect(this.model.author()).toBe(this.model.author());
            });
        });

        context("when author information is not present", function() {
            beforeEach(function() {
                this.model.unset("author");
                this.model.unset("actor");
            });

            it("returns undefined", function() {
                expect(this.model.author()).toBeUndefined();
            });
        });
    });

    describe("#comments", function() {
        beforeEach(function() {
            this.model.set({
                comments: [
                    {
                        body: "I'm cold.'",
                        author: {
                            image: { original: "/foo", icon: "/bar" },
                            id: "1234",
                            lastName: "Smith",
                            firstName: "Bob"
                        },
                        timestamp: "2011-12-15 12:34:56"
                    }
                ]
            });
            this.model.set({id: 5});
            this.comments = this.model.comments();
        });

        it("returns a CommentSet", function() {
            expect(this.comments).toBeA(chorus.collections.CommentSet);
        });

        it("memoizes", function() {
            expect(this.comments).toBe(this.model.comments());
        });

        it("contains the activity item's comments", function() {
            var commentsJson = this.model.get("comments");
            expect(this.comments.models[0].get("body")).toBe(commentsJson[0].body);
            expect(this.comments.models[0].get("timestamp")).toBe(commentsJson[0].timestamp);
            expect(this.comments.models[0].author().get("firstName")).toBe(commentsJson[0].author.firstName);
        });
    });

    describe("#reindexError", function() {
        it("sets the errorModelId to be the id of the activity", function() {
            this.model = backboneFixtures.activity.gnipStreamImportFailed();
            this.model.reindexError();
            expect(this.model.get('errorModelId')).toBe(this.model.get('id'));
        });

        it("does not set the error model id if the activity is not a failure", function() {
            this.model = backboneFixtures.activity.gnipStreamImportSuccess();
            this.model.reindexError();
            expect(this.model.get('errorModelId')).toBeUndefined();
        });
    });

    describe("#attachments", function() {
        beforeEach(function() {
            this.model.set({
                attachments: [
                    { entityType: "workfile", id: 1 },
                    { entityType: "attachment", id: 2 },
                    { entityType: "dataset", id: 3 },
                    { entityType: "workfile", entitySubtype: "alpine", id: 4 },
                    { entityType: "work_flow_result", id: "0.12345"}
                ]
            });
            this.attachments = this.model.attachments();
        });

        it("returns an array of file models (Workfiles, Attachments Datasets)", function() {
            expect(this.attachments[0]).toBeA(chorus.models.Workfile);
            expect(this.attachments[1]).toBeA(chorus.models.Attachment);
            expect(this.attachments[2]).toBeA(chorus.models.WorkspaceDataset);
            expect(this.attachments[3]).toBeA(chorus.models.AlpineWorkfile);
            expect(this.attachments[4]).toBeA(chorus.models.WorkFlowResult);
        });

        it("memoizes", function() {
            expect(this.attachments).toBe(this.model.attachments());
        });
    });
});
