describe("chorus.dialogs.EditProjectStatus", function() {
    beforeEach(function() {
        this.workspace = backboneFixtures.workspace();
        this.workspace.set('projectStatus', 'at_risk');
        this.dialog = new chorus.dialogs.EditProjectStatus({ model: this.workspace });
    });

    describe("render", function() {
        beforeEach(function() {
            this.dialog.render();
        });

        it("selects the appropriate project status option from the model", function () {
            expect(this.dialog.$("select[name='projectStatus']").val()).toEqual('at_risk');
        });

        context("submitting the form with valid data", function() {
            beforeEach(function() {
                this.reason = 'Because I said so!';
                spyOnEvent($(document), "close.facebox");
                spyOn(this.dialog.model, "save").andCallThrough();
                this.dialog.$("select[name='projectStatus']").val('needs_attention');
                this.dialog.$('input[name=reason]').val(this.reason).keyup();
                this.dialog.$('.submit').click();
            });

            it("saves the workspace", function() {
                expect(this.dialog.model.save).toHaveBeenCalled();
            });

            it("updates the project status", function() {
                var json = this.server.lastUpdateFor(this.dialog.model).json();
                expect(json['workspace']['project_status']).toEqual('needs_attention');
            });

            it("updates the project status reason", function() {
                var json = this.server.lastUpdateFor(this.dialog.model).json();
                expect(json['workspace']['project_status_reason']).toEqual(this.reason);
            });
        });

        it("disables the form until a status change reason is supplied", function () {
            expect(this.dialog.$('button.submit')).toBeDisabled();
            this.dialog.$('input[name=reason]').val('Because I said so!').keyup();
            expect(this.dialog.$('button.submit')).not.toBeDisabled();
        });

    });
});
