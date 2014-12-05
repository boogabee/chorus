describe("chorus.dialogs.DataSourceAccount", function() {
    beforeEach(function() {
        this.dataSource = backboneFixtures.gpdbDataSource();
        this.dialog = new chorus.dialogs.DataSourceAccount({
            dataSource: this.dataSource,
            title: t("data_sources.account.add.title")
        });
        this.dialog.launchModal();
        this.dialog.render();
    });

    describe("#render", function() {
        it("has the right title based on the launch element", function() {
            expect(this.dialog.title).toMatchTranslation("data_sources.account.add.title");
        });

        it("does not autocomplete password inputs", function(){
            var passwordField = this.dialog.$("input[name=dbPassword]");
            expect(passwordField).toHaveAttr("autocomplete", "off");
        });
    });

    describe("#makeModel", function() {
        it("gets the current user's account on the data source that is the current page model", function() {
            expect(this.dialog.model).toBe(this.dataSource.accountForCurrentUser());
        });
    });

    describe("when the form is submitted", function() {
        beforeEach(function() {
            this.account = this.dialog.model;
            spyOn(this.account, 'save').andCallThrough();

            this.dialog.$("input[name=dbUsername]").val("office");
            this.dialog.$("input[name=dbPassword]").val("howard875huge");
            this.dialog.$("form").submit();
        });

        it("sets the database username and password fields on the model", function() {
            expect(this.account.get("dbUsername")).toBe("office");
            expect(this.account.get("dbPassword")).toBe("howard875huge");
        });

        it("saves the model with the fields from the form", function() {
            expect(this.account.save).toHaveBeenCalled();
        });

        describe("when the save completes", function() {
            beforeEach(function() {
                spyOn(this.dialog, 'showSavedToast');
                spyOn(this.dialog, 'closeModal').andCallThrough();
                this.account.trigger("saved");
            });

            it("closes the dialog", function() {
                expect(this.dialog.closeModal).toHaveBeenCalled();
            });

            it("shows the toast", function() {
                expect(this.dialog.showSavedToast).toHaveBeenCalled();
            });
        });
    });

    describe("when options.reload=true", function() {
        beforeEach(function() {
            spyOn(chorus.router, "reload");
            this.dialog.options.reload = true;
        });

        describe("after saving", function() {
            beforeEach(function() {
                this.dialog.$("input[name=dbUsername]").val("office");
                this.dialog.$("input[name=dbPassword]").val("howard875huge");
                this.dialog.$("form").submit();
            });

            it("calls chorus.router.reload() after saving", function() {
                expect(chorus.router.reload).not.toHaveBeenCalled();
                this.server.completeCreateFor(this.dialog.model);
                expect(chorus.router.reload).toHaveBeenCalled();
            });

            it("does not navigate back", function() {
                this.server.completeCreateFor(this.dialog.model);
                expect(window.history.back).not.toHaveBeenCalled();
            });
        });
    });

    describe("when options.goBack=true", function() {
        beforeEach(function() {
            this.dialog.options.goBack = true;
        });

        describe("when the dialog is dismissed", function() {
            it("goes back one page in the browser", function() {
                this.dialog.$("button.cancel").click();
                expect(window.history.back).toHaveBeenCalled();
            });
        });
    });

    describe("when options.goBack=false", function() {
        beforeEach(function() {
            this.dialog.options.goBack = false;
        });

        describe("when the dialog is dismissed", function() {
            it("does not go back one page in the browser", function() {
                this.dialog.$("button.cancel").click();
                expect(window.history.back).not.toHaveBeenCalled();
            });
        });
    });

    describe("#showSavedToast", function(){
        it("broadcasts a toast with the right translation", function(){
            spyOn(chorus, "toast");
            this.dialog.showSavedToast();
            expect(chorus.toast).toHaveBeenCalledWith("data_sources.account.updated.toast", {dataSourceName: this.dataSource.name()});
        });
    });
});
