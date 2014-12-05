describe("chorus.views.UserItem", function() {
    beforeEach(function () {
        this.user = backboneFixtures.user();
        //setLoggedInUser({'username': this.user.get('username')});
        this.view = new chorus.views.UserItem({model: this.user});
    });

    describe("#render", function () {
        beforeEach(function() {
            this.view.render();
        });

        describe("when the user is an admin", function () {
            beforeEach(function () {
                this.user.set({admin: true});
                this.view.render();
            });

            it("displays the admin badge", function() {
                expect(this.view.$('.administrator.tag')).toContainTranslation('users.administrator');
            });
        });

        describe("when the user is a developer", function () {
            beforeEach(function () {
                this.user.set({developer: true});
                this.view.render();
            });

            it("displays the developer badge", function() {
                expect(this.view.$('.developer.tag')).toContainTranslation('users.developer');
            });
        });
    });

});
