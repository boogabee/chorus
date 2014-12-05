describe("chorus.alerts.TagDelete", function() {
    var tagName = "aTagName";

    beforeEach(function() {
        this.alert = new chorus.alerts.TagDelete({model: new chorus.models.Tag({id: 10, name: tagName}) });
    });

    it("does not re-render when the model changes", function() {
        expect(this.alert.persistent).toBeTruthy();
    });

    it("has the correct title", function() {
        expect(this.alert.title).toBe(t("tag.delete.title", {tagName: tagName}));
    });

    it("has the correct text", function() {
        expect(this.alert.text).toBe(t("tag.delete.text"));
    });

    describe("when the tag deletion is successful", function() {
        beforeEach(function() {
            spyOn(chorus, "toast");
            spyOn(chorus.router, "navigate");
            spyOnEvent($(document), "close.facebox");
            this.alert.model.trigger("destroy", this.alert.model);
        });

        it("should display a toast", function() {
            expect(chorus.toast).toHaveBeenCalledWith("tag.delete.toast", {tagName: tagName});
        });
    });
});
