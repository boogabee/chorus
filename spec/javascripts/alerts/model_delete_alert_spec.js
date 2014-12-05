describe("chorus.alerts.ModelDelete", function() {
    beforeEach(function() {
        this.model = new chorus.models.User();
        this.dialog = this.alert = new chorus.alerts.ModelDelete({  model: this.model });
        stubModals();
        this.alert.launchModal();
        this.alert.redirectUrl = "/partyTime";
        this.alert.text = "Are you really really sure?";
        this.alert.title = "A standard delete alert";
        this.alert.ok = "Delete It!";
        this.alert.deleteMessage = "It has been deleted";
    });

    itBehavesLike.aDialogWithSomethingToFocusOn();

    describe("clicking delete", function() {
        beforeEach(function() {
            this.alert.render();
            spyOn(this.alert.model, "destroy");
            this.alert.$("button.submit").click();
        });

        it("deletes the model", function() {
            expect(this.alert.model.destroy).toHaveBeenCalled();
        });

        it("sets the delete button to the loading state", function() {
            expect(this.alert.$("button.submit").isLoading()).toBeTruthy();
        });

        describe("when the model deletion is successful", function() {
            beforeEach(function() {
                spyOn(chorus.router, "navigate");
                spyOnEvent($(document), "close.facebox");
                spyOn(chorus, "toast");
                this.deleteParams = {foo: "bar"};
                spyOn(this.alert, "deleteMessageParams").andReturn(this.deleteParams);
            });

            it("dismisses the alert", function () {
                this.alert.model.trigger("destroy", this.alert.model);
                expect("close.facebox").toHaveBeenTriggeredOn($(document));
            });

            it("navigates to the redirectUrl", function() {
                this.alert.model.trigger("destroy", this.alert.model);
                expect(chorus.router.navigate).toHaveBeenCalledWith("/partyTime");
            });

            it("displays the delete success toast message", function() {
                this.alert.model.trigger("destroy", this.alert.model);
                expect(this.alert.deleteMessageParams).toHaveBeenCalled();
                expect(chorus.toast).toHaveBeenCalledWith(this.alert.deleteMessage, this.deleteParams);
            });

            it("triggers a pageevent <entityType>:deleted", function() {
                spyOn(chorus.PageEvents, 'trigger');
                this.alert.model.trigger("destroy", this.alert.model);
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("user:deleted", this.alert.model);
            });

            context("when the alert does NOT have a redirect url", function() {
                it("does not navigate", function() {
                    delete this.alert.redirectUrl;
                    this.alert.model.trigger("destroy", this.alert.model);
                    expect(chorus.router.navigate).not.toHaveBeenCalled();
                });
            });
        });

        describe("when the model deletion fails", function() {
            beforeEach(function() {
                spyOnEvent($(document), "close.facebox");
                this.alert.resource.set({serverErrors: { fields: { a: { INVALID : { message: "Hi there"}}} }});
                this.alert.model.trigger("destroyFailed", this.alert.model);
            });

            it("does not dismiss the dialog", function() {
                expect("close.facebox").not.toHaveBeenTriggeredOn($(document));
            });

            it("puts the button out of the loading state", function() {
                expect(this.alert.$("button.submit").isLoading()).toBeFalsy();
            });
        });
    });

    describe("clicking cancel", function() {
        beforeEach(function() {
            this.alert.render();
            this.alert.$("button.cancel").click();
            spyOn(chorus.router, "navigate");
            this.alert.model.trigger("destroy", this.alert.model);
        });

        it("unbinds events on the model", function() {
            expect(chorus.router.navigate).not.toHaveBeenCalled();
        });
    });
});
