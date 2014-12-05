describe('chorus.views.LocationPicker.SelectorView', function() {
    beforeEach(function() {
        this.childPicker = jasmine.createSpyObj("child picker", ['hide', 'isHidden']);
        this.view = new chorus.views.LocationPicker.SelectorView({
            childPicker: this.childPicker
        });
    });

    it("does not call maybeHideChildren if the child picker is already hidden", function() {
        this.childPicker.isHidden.andReturn(true);
        this.view.setState(this.view.STATES.HIDDEN);
        expect(this.childPicker.hide).not.toHaveBeenCalled();
    });
});