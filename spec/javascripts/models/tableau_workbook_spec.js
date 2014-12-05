describe("chorus.models.TableauWorkbook", function () {
    beforeEach(function () {
        this.model = new chorus.models.TableauWorkbook({dataset: backboneFixtures.workspaceDataset.datasetTable({id: '42', workspace: {id: '43'}})});
    });

    it("has the correct url", function () {
        expect(this.model.url()).toBe("/workspaces/43/datasets/42/tableau_workbooks");
    });

    describe("validations", function() {
        beforeEach(function() {
            this.model.set({
                name: "name",
                tableau_username: "tableau_username",
                tableau_password: "tableau_password"
            });
        });

        it("validates the name is present", function() {
            this.model.set({name: ""});
            expect(this.model.performValidation()).toBeFalsy();
        });

        it("validates the username is present", function() {
            this.model.set({tableau_username: ""});
            expect(this.model.performValidation()).toBeFalsy();
        });

        it("validates the password is present", function() {
            this.model.set({tableau_password: ""});
            expect(this.model.performValidation()).toBeFalsy();
        });

        it("passes validation when all attributes are present", function() {
            expect(this.model.performValidation()).toBeTruthy();
        });
    });
});
