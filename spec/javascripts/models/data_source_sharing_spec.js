describe("chorus.dialogs.DataSourceSharing", function() {
    beforeEach(function() {
        this.sharing = new chorus.dialogs.DataSourceSharing({dataSourceId: 1});
    });

    it("posts to the correct endpoint", function() {
        this.sharing.save();
        var sharingPost = this.server.lastCreateFor(this.sharing);
        expect(sharingPost.url).toContain('/data_sources/1/sharing');
    });
});
