describe('chorus.models.WorkFlowResult', function() {
    beforeEach(function() {
        this.model = new chorus.models.WorkFlowResult({workfileId: 2, id: "0.12334455634"});
    });

    it("has a showUrl", function() {
        var path = "/alpinedatalabs/main/chorus.do?method=showResults&session_id=" +
            chorus.session.get("sessionId") +
            "&workfile_id=2&result_id=0.12334455634";
        expect(this.model.showUrl()).toBe(path);
    });

    it("has an iconUrl", function() {
        expect(this.model.iconUrl()).toBe("/images/workfiles/icon/afm.png");
    });

    it("has a name", function() {
        expect(this.model.name()).toMatchTranslation("work_flow_result.attachment_name");
    });

    it("has its own page", function() {
        expect(this.model.hasOwnPage()).toBeTruthy();
    });

    it("opens its show url as an external page", function() {
        expect(this.model.useExternalLink()).toBeTruthy();
    });
});