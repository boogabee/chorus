jasmine.sharedExamples.aPageWithMultiSelect = function() {
    describe("multiple selection", function() {
        beforeEach(function() {
            spyOn(chorus.PageEvents, "trigger").andCallThrough();
        });

        it("should have a checkbox", function() {
            expect(this.page.$(".multiselect input[type=checkbox].select_all")).toExist();
        });

        describe("when the 'select all' checkbox is checked", function() {
            it("triggers the 'selectAll' page event", function() {
                var checkbox = this.page.$(".multiselect .select_all");
                checkbox.prop("checked", true);
                checkbox.change();
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("selectAll");
            });

            describe("zzz when there is only one item in the list", function () {
                beforeEach(function () {
                    this.singleModel = {};
                    spyOn(this.page.mainContent.content, 'selectableModels').andReturn([this.singleModel]);
                });

                it("broadcasts a single model:selected event", function () {
                    var checkbox = this.page.$(".multiselect .select_all");
                    checkbox.prop("checked", true);
                    checkbox.change();

                    var selectedEvent = this.page.mainContent.content.eventName + ':selected';
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith(selectedEvent, jasmine.any(chorus.models.Base));
                });
            });



        });

        describe("when the 'select all' checkbox is unchecked", function() {
            it("triggers the 'selectNone' page event", function() {
                var checkbox = this.page.$(".multiselect .select_all");
                checkbox.prop("checked", false);
                checkbox.change();
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("selectNone");
            });
        });

        it("subscribes to 'noneSelected'", function () {
            var checkbox = this.page.$(".multiselect .select_all");
            checkbox.prop("checked", true);
            chorus.PageEvents.trigger("noneSelected");
            expect(checkbox.prop("checked")).toBeFalsy();
        });

        it("subscribes to 'allSelected'", function () {
            var checkbox = this.page.$(".multiselect .select_all");
            checkbox.prop("checked", false);
            chorus.PageEvents.trigger("allSelected");
            expect(checkbox).toBeChecked();
            expect(checkbox.prop('indeterminate')).toBeFalsy();
        });

        it("subscribes to 'unselectAny'", function () {
            var checkbox = this.page.$(".multiselect .select_all");
            checkbox.prop("checked", true);
            chorus.PageEvents.trigger("unselectAny");
            expect(checkbox).toBeChecked();
            expect(checkbox.prop('indeterminate')).toBeTruthy();
        });

        context("when nothing has been checked", function () {
            it("does not display the multiple selection actions", function() {
                expect(this.page.$(".multiple_selection .actions")).not.toExist();
            });
        });

        context("when only ONE row has been checked", function() {
            beforeEach(function() {
                this.modalSpy = stubModals();
                var oneModelCollection = this.page.collection.clone().reset([this.page.collection.first()]);
                chorus.PageEvents.trigger(this.page.mainContent.content.eventName + ":checked", oneModelCollection);
            });

            it("does not display the multiple selection actions", function() {
                expect(this.page.$(".multiple_selection .actions")).not.toBeVisible();
            });
        });

        context("when at least TWO rows have been checked", function() {
            beforeEach(function() {
                this.modalSpy = stubModals();
                var someModel = this.page.collection.first();
                var rowModels = this.page.collection.clone().reset([someModel, new chorus.models[someModel.constructorName]()]);
                chorus.PageEvents.trigger(this.page.mainContent.content.eventName + ":checked", rowModels);
            });

            it("displays the multiple selection actions", function() {
                expect(this.page.$(".multiple_selection .actions")).not.toHaveClass("hidden");
            });

            it("has an action to edit tags", function() {
                expect(this.page.$(".multiple_selection a.edit_tags")).toExist();
            });

            itBehavesLike.aDialogLauncher(".multiple_selection a.edit_tags", chorus.dialogs.EditTags);
        });
    });
};
