describe("chorus.views.PrimaryActionPanel", function () {
//    var randomDialog = chorus.dialogs[_.sample(Object.keys(chorus.dialogs))];

    var actions = [
        {name: 'download', target: chorus.dialogs.RunAndDownload},
        {name: 'display', target: '/destination'},
        {name: 'explore', target: '/final/destination'}
    ];

    beforeEach(function () {
        this.workspace = backboneFixtures.workspace();
        this.workspace.loaded = false;
        var constructionParams = {pageModel: this.workspace, actions: actions};
        this.view = new chorus.views.PrimaryActionPanel(constructionParams);
    });

    describe("a page with primary actions", function () {
        beforeEach(function () {
            this.page = new chorus.pages.Base();
            this.page.primaryActionPanel = this.view;
            this.page.render();
        });

        itBehavesLike.aPageWithPrimaryActions(actions);
    });
});