jasmine.sharedExamples.aDialogWithSomethingToFocusOn = function() {
    describe("on reveal", function() {
        beforeEach(function() {
            if(!jasmine.isSpy($.facebox)) { stubModals(); }
            spyOn($.fn, 'focus');
            this.dialog.launchModal();
            $(document).trigger('reveal.facebox');
        });

        it("focuses on the assigned focusSelector", function() {
            expect($.fn.focus).toHaveBeenCalled();
            expect($.fn.focus.lastCall().object.selector).toBe(this.dialog.focusSelector);
        });
    });
};