jasmine.sharedExamples.aDialogLauncher = function(linkHtmlClass, dialogClass) {
    context("clicking the " + linkHtmlClass + " link", function() {
        beforeEach(function() {
            this.modalSpy.reset();
            this.view = this.page || this.view || this.dialog;
            $('#jasmine_content').append(this.view.$el);
            this.view.$(linkHtmlClass).click();
        });

        it("should launch the " + dialogClass.prototype.constructorName + " dialog once", function() {
            expect(this.modalSpy).toHaveModal(dialogClass);
            expect(this.modalSpy.modals().length).toBe(1);
        });
    });
};
