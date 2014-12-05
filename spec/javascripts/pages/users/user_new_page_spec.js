describe("chorus.pages.UserNewPage", function() {
    beforeEach(function() {
        this.page = new chorus.pages.UserNewPage();
    });

    it("has a helpId", function() {
        expect(this.page.helpId).toBe("user_new");
    });

    describe("#setup", function() {
        describe("when the configuration fetch completes", function() {

        });
    });

    describe("#render", function(){
        beforeEach(function() {
            this.page.render();
        });

        it("has the correct breadcrumbs", function() {
            expect(this.page.$("#breadcrumbs .breadcrumb a").eq(0)).toHaveHref("#/");
            expect(this.page.$("#breadcrumbs .breadcrumb a").eq(0)).toContainTranslation("breadcrumbs.home");
            expect(this.page.$("#breadcrumbs .breadcrumb a").eq(1)).toHaveHref("#/users");
            expect(this.page.$("#breadcrumbs .breadcrumb a").eq(1)).toContainTranslation("breadcrumbs.users");
            expect(this.page.$("#breadcrumbs .breadcrumb .slug")).toContainTranslation("breadcrumbs.new_user");
        });

        it("has the correct title", function() {
            expect(this.page.$(".content_header")).toContainTranslation("users.new_user");
        });

        it("has the correct subtitle", function() {
            expect(this.page.$(".content_details")).toContainTranslation("users.details");
        });

        context("when external auth is enabled", function() {
            beforeEach(function() {
                chorus.models.Config.instance().set({ externalAuthEnabled: true });
                this.page = new chorus.pages.UserNewPage();
                this.page.render();
            });

            it("instantiates a user new ldap view", function() {
                expect(this.page.$(".user_new_ldap")).toExist();
                expect(this.page.mainContent.content).toBeA(chorus.views.UserNewLdap);
            });
        });

        context("when external auth is *not* enabled", function() {
            beforeEach(function() {
                chorus.models.Config.instance().set({ externalAuthEnabled: false });
                this.page = new chorus.pages.UserNewPage();
                this.page.render();
            });

            it("instantiates the normal user new view", function() {
                expect(this.page.$(".user_new")).toExist();
                expect(this.page.mainContent.content).toBeA(chorus.views.UserNew);
            });
        });
    });
});
