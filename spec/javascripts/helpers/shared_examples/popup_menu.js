jasmine.sharedExamples.PopupMenu = function(linkSelector, menuSelector, indicatorSelector) {
    if (indicatorSelector) {
        describe("when opened with an indicator", function() {
            it('activates the indicator', function(){
                this.view.render();
                this.view.$(linkSelector).click();
                expect(this.view.$(indicatorSelector)).toHaveClass("active");
            });

            describe("when another popup is opened on the page", function() {
                beforeEach(function() {
                    this.view.render();
                    this.view.$(linkSelector).click();
                    expect(this.view.$(menuSelector)).not.toHaveClass("hidden");
                    chorus.PopupMenu.toggle(this.view, '.fake_selector');
                });

                it("deactivates the indicator", function() {
                    expect(this.view.$(indicatorSelector)).not.toHaveClass("active");
                });
            });
        });
    }
    
    describe("when another popup is opened on the page", function() {
        beforeEach(function() {
            this.view.render();
            this.view.$(linkSelector).click();
            expect(this.view.$(menuSelector)).not.toHaveClass("hidden");
            chorus.PopupMenu.toggle(this.view, '.fake_selector');
        });

        it("dismisses the popup", function() {
            expect(this.view.$(menuSelector)).toHaveClass("hidden");
        });
    });
};