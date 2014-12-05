describe("chours.views.DatePicker", function () {
    beforeEach(function () {
        this.view = new chorus.views.DatePicker({selector: "foo"});
        this.view.render();
    });

    describe("the start date picker", function() {
        it("should have the correct placeholder text", function() {
            expect(this.view.$(".foo input.month").attr("placeholder")).toContainTranslation("datepicker.placeholder.month");
            expect(this.view.$(".foo input.day").attr("placeholder")).toContainTranslation("datepicker.placeholder.day");
            expect(this.view.$(".foo input.year").attr("placeholder")).toContainTranslation("datepicker.placeholder.year");
        });

        it("should have the default date set to today", function() {
            var now = new Date();
            expect(this.view.$(".foo input.month").val()).toBe((now.getMonth() + 1).toString());
            expect(this.view.$(".foo input.day").val()).toBe((now.getDate()).toString());
            expect(this.view.$(".foo input.year").val()).toBe((now.getFullYear()).toString());
        });

        describe("changing the date", function () {
            beforeEach(function () {
                this.actualDate = new Date("3013", "6", "12");
                this.view.$(".foo input.month").val((this.actualDate.getMonth() + 1).toString());
                this.view.$(".foo input.day").val((this.actualDate.getDate()).toString());
                this.view.$(".foo input.year").val((this.actualDate.getFullYear()).toString());
            });

            it("returns the picked date", function () {
                var date = this.view.getDate().toDate();
                expect(date).toEqual(this.actualDate);
            });
        });
    });

    describe("#disable", function () {
        beforeEach(function () {
            spyOn(datePickerController, "disable");
            this.view.disable();
        });

        it("should disable the datepicker", function () {
            var $date = this.view.$(".foo input.year");
            expect(datePickerController.disable).toHaveBeenCalledWith($date.attr("id"));
            expect(this.view.daySelector).toBeDisabled();
            expect(this.view.yearSelector).toBeDisabled();
            expect(this.view.monthSelector).toBeDisabled();
        });
    });

    describe("#enable", function () {
        beforeEach(function () {
            spyOn(datePickerController, "enable");
            this.view.disable();
            this.view.enable();
        });

        it("should enable the datepicker", function () {
            var $date = this.view.$(".foo input.year");
            expect(datePickerController.enable).toHaveBeenCalledWith($date.attr("id"));
            expect(this.view.daySelector).not.toBeDisabled();
            expect(this.view.yearSelector).not.toBeDisabled();
            expect(this.view.monthSelector).not.toBeDisabled();
        });
    });
});