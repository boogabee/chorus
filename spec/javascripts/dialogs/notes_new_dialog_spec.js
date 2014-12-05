describe("chorus.dialogs.NotesNewDialog", function () {
    function staticStuff() {
        it("has the right title", function () {
            expect(this.dialog.$(".dialog_header h1")).toContainTranslation("notes.new_dialog.title");
        });

        it("has the right button text", function () {
            expect(this.dialog.$("button.submit").text().trim()).toMatchTranslation("notes.button.create");
        });
    }

    describe("when passed an independent model", function () {
        beforeEach(function () {
            this.model = backboneFixtures.hdfsDataSource();
            this.dialog = new chorus.dialogs.NotesNew({pageModel: this.model});
            $('#jasmine_content').append(this.dialog.el);
            this.dialog.render();
        });

        it("creates the correct model", function () {
            expect(this.dialog.model).toBeA(chorus.models.Note);
        });

        it("does not pass on a workspaceId", function () {
            var noteWorkspaceID = this.dialog.model.get("workspaceId");
            expect(noteWorkspaceID).toBeUndefined();
        });

        it("passes on the model's ID", function () {
            expect(this.dialog.model.get("entityId")).toBe(this.model.id);
        });

        it("passes on the model's entity type", function () {
            expect(this.dialog.model.get("entityType")).toBe(this.model.entityType);
        });

        it("has the right placeholder", function () {
            var placeholder = this.dialog.$("textarea[name=body]").attr("placeholder");
            expect(placeholder).toContainTranslation("notes.placeholder", {noteSubject: this.model.entityType});
        });

        describe("when the model is a sql-type-ish data_source", function () {
            beforeEach(function () {
                this.model = _.sample([backboneFixtures.gpdbDataSource(), backboneFixtures.gpdbDataSource()]);
                this.specialCaseEntityType = 'data_source';
                this.dialog = new chorus.dialogs.NotesNew({pageModel: this.model});
                $('#jasmine_content').append(this.dialog.el);
                this.dialog.render();
            });

            it("passes on the model's entity type", function () {
                expect(this.dialog.model.get("entityType")).toBe(this.specialCaseEntityType);
            });

            it("has a more generic placeholder", function () {
                var placeholder = this.dialog.$("textarea[name=body]").attr("placeholder");
                expect(placeholder).toContainTranslation("notes.placeholder", {noteSubject: this.specialCaseEntityType});
            });
        });

        it("stores the correct pageModel", function () {
            expect(this.dialog.pageModel).not.toBeUndefined();
        });

        staticStuff();
    });

    describe("when passed a model associated with a workspace", function () {
        beforeEach(function () {
            this.pageModel = backboneFixtures.job();
            this.dialog = new chorus.dialogs.NotesNew({pageModel: this.pageModel});
            $('#jasmine_content').append(this.dialog.el);
            this.dialog.render();
        });

        it("creates the correct model", function () {
            expect(this.dialog.model).toBeA(chorus.models.Note);
        });

        it("passes on the model's entity type", function () {
            expect(this.dialog.model.get("entityType")).toBe("Job");
        });

        it("passes on the model's ID", function () {
            expect(this.dialog.model.get("entityId")).toBe(this.pageModel.id);
        });

        it("passes on the model's workspaceId", function () {
            var noteWorkspaceID = this.dialog.model.get("workspaceId");
            expect(noteWorkspaceID).toBeDefined();
            expect(noteWorkspaceID).toBe(this.pageModel.workspace().id);
        });

        it("has the right placeholder", function () {
            var placeholder = this.dialog.$("textarea[name=body]").attr("placeholder");
            expect(placeholder).toContainTranslation("notes.placeholder", {noteSubject: "Job"});
        });

        it("stores the correct pageModel", function () {
            expect(this.dialog.pageModel).not.toBeUndefined();
        });

        staticStuff();
    });

    describe("when passed a model with a displayEntityType", function () {
        beforeEach(function () {
            this.pageModel = backboneFixtures.job();
            this.pageModel.displayEntityType = 'Sassafras';
            this.dialog = new chorus.dialogs.NotesNew({pageModel: this.pageModel});
            $('#jasmine_content').append(this.dialog.el);
            this.dialog.render();
        });

        it("respects displayEntityType", function () {
            var placeholder = this.dialog.$("textarea[name=body]").attr("placeholder");
            expect(placeholder).toContainTranslation("notes.placeholder", {noteSubject: this.pageModel.displayEntityType});
        });

        it("passes on the model's entity type", function () {
            expect(this.dialog.model.get("entityType")).toBe("Job");
        });

    });
});